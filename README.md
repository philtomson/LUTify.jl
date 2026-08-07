# LUTify.jl

Takes a function with one input and turns it into a lookup table. This can be useful for modelling hardware, for example. Take the sin function — it's difficult to implement in hardware without resorting to something like CORDIC ...or lookup tables.

## Usage

### Standard LUT (direct function evaluation)

```julia
using LUTify

sinlut = LUT(sin, 0.0:(π/100):2π)
value = sinlut(π/4)  # returns pre-computed value from table
```

### CORDIC-based LUT

CORDIC (COordinate Rotation Digital Computer) computes trigonometric functions using only shifts and adds — ideal for hardware. LUTify can generate lookup tables using CORDIC as the reference generator:

```julia
using LUTify

# Evaluate sin/cos directly via CORDIC
sin_val = cordic_sin(π/4, 16)   # ~15 bits precision
cos_val = cordic_cos(π/3, 16)

# Build a quantized lookup table
sinlut = LUT_cordic(:sin, 0.0:(π/100):2π, 8, 16)  # 8-bit, 16 iterations
coslut = LUT_cordic(:cos, 0.0:(π/100):2π, 8, 16)
```

### Multi-variable LUT

```julia
exprlut = LUT(:(x + y + z), [(:x, 0.0:0.1:10.0), (:y, 0.0:0.1:10.0), (:z, 0.0:0.1:10.0)])
value = exprlut(4.2, 3.5, 1.0)
```

## CORDIC Reference Table

The `cordic_angles(n)` function generates the angle lookup table used by CORDIC:

| n (iterations) | Max error (float sin) | Approx. precision |
|---|---|---|
| 4 | 1.2×10⁻¹ | ~3 bits |
| 8 | 7.4×10⁻³ | ~7 bits |
| 12 | 4.4×10⁻⁴ | ~11 bits |
| 16 | 3.0×10⁻⁵ | ~15 bits |
| 20 | 1.7×10⁻⁶ | ~20 bits |

A 16-element angle table (~64 bytes at 32-bit) replaces a full sin LUT (256 × 8-bit = 256 bytes) with ~75% memory savings, at the cost of iterative computation.

### atan2 via CORDIC

`cordic_atan2(y, x, n)` computes the two-argument arctangent using CORDIC rotation mode.
It starts from point (K, 0) on the positive x-axis and rotates toward the target direction (x, y).

| Iterations | Max Absolute Error (full circle) |
|------------|----------------------------------|
| 8          | ~2×10⁻¹                          |
| 16         | ~3×10⁻¹                          |

For higher precision in production code, increase `n` or use Julia's built-in `atan(y, x)`.

### Hyperbolic Functions via CORDIC

`cordic_cosh`, `cordic_sinh`, and `cordic_exp` use **hyperbolic CORDIC rotation mode** with angles `atanh(2^(-i))` for i ≥ 1.
Range reduction decomposes `z = k·ln(2) + r` so the core iteration always works on small arguments,
using exact powers of 2 for the integer part.

| Function | Identity | Max Error (n=16, range [-5, 5]) |
|----------|----------|--------------------------------|
| `cordic_cosh(z)` | — | ~2×10⁻³ |
| `cordic_sinh(z)` | — | ~2×10⁻³ |
| `cordic_exp(z)` | cosh(z) + sinh(z) | ~4×10⁻³ |

Verified identities:
- `cosh²(z) - sinh²(z) = 1`
- `exp(z) = cosh(z) + sinh(z)`

## API

| Function | Description |
|---|---|
| `LUT(fn, range)` | Build a lookup table from any callable over a step range |
| `LUT(expr, [(sym, range), ...])` | Build a multi-var lookup table from an expression |
| `build_lut(fn, vars)` | Low-level helper: generate array via `@eval` comprehension |
| `cordic_angles(n)` | Generate CORDIC angle table `atan.(2 .^ (-0:(n-1)))` |
| `cordic_sin(θ, n)` | Compute sin(θ) via CORDIC with `n` iterations |
| `cordic_cos(θ, n)` | Compute cos(θ) via CORDIC with `n` iterations |
| `cordic_atan2(y, x, n)` | Compute atan2(y,x) via CORDIC rotation mode |
| `cordic_cosh(z, n)` | Compute cosh(z) via hyperbolic CORDIC |
| `cordic_sinh(z, n)` | Compute sinh(z) via hyperbolic CORDIC |
| `cordic_exp(z, n)` | Compute exp(z) = cosh(z) + sinh(z) via hyperbolic CORDIC |
| `LUT_cordic(fn, range, bits, n)` | Build a quantized LUT using CORDIC reference values |

## TODO

- [x] CORDIC support (sin, cos, tan)
- [ ] Export lookup tables to HDL (Verilog/VHDL)
- [ ] Full test coverage
- [ ] Support for custom functions via CORDIC-like algorithms (exp, atan2, etc.)
