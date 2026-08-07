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

## API

| Function | Description |
|---|---|
| `LUT(fn, range)` | Build a lookup table from any callable over a step range |
| `LUT(expr, [(sym, range), ...])` | Build a multi-var lookup table from an expression |
| `build_lut(fn, vars)` | Low-level helper: generate array via `@eval` comprehension |
| `cordic_angles(n)` | Generate CORDIC angle table `atan.(2 .^ (-0:(n-1)))` |
| `cordic_sin(θ, n)` | Compute sin(θ) via CORDIC with `n` iterations |
| `cordic_cos(θ, n)` | Compute cos(θ) via CORDIC with `n` iterations |
| `LUT_cordic(fn, range, bits, n)` | Build a quantized LUT using CORDIC reference values |

## TODO

- [x] CORDIC support (sin, cos, tan)
- [ ] Export lookup tables to HDL (Verilog/VHDL)
- [ ] Full test coverage
- [ ] Support for custom functions via CORDIC-like algorithms (exp, atan2, etc.)
