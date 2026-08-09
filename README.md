# LUTify.jl

Takes a function with one input and turns it into a lookup table. This can be useful for modelling hardware, for example. Take the sin function — it's difficult to implement in hardware without resorting to something like CORDIC ...or lookup tables.


## Getting Started

### Installation

```julia
using Pkg
Pkg.add("LUTify")
```

### Quick Start

```julia
using LUTify

# 1. Create a lookup table from sin over [0, 2π] with 64 points
sinlut = LUT(sin, range(0.0, stop=2π, length=64))

# 2. Evaluate interpolated values
v = sinlut(π/4)  # ≈ sin(π/4) from the table

# 3. Export as Verilog module (8-bit data width)
verilog_code = export_verilog(sinlut, bits=8, fn_name="sin")
open("sin_lut.v", "w") do f; write(f, verilog_code); end

# 4. Generate a self-contained testbench and simulate
testbench = export_testbench(sinlut, bits=8)
open("tb_sin.v", "w") do f; write(f, testbench); end
system("iverilog -o tb_sin tb_sin.v sin_lut.v && vvp tb_sin")

# 5. Or export memory files for FPGA toolchains
export_memfile(sinlut, "sin_lut.hex"; format=:hex)   # Intel/Altera HEX
export_memfile(sinlut, "sin_lut.mif"; format=:mif)   # Xilinx MIF
export_memfile(sinlut, "sin_lut.coe"; format=:coe)   # Xilinx COE
```

### Multi-var Lookup Tables

LUTify supports lookup tables with multiple input variables. The addressing follows a
row-major stride scheme compatible with `get_idx`:

```julia
using LUTify

# 2-variable table: z = x + y, x ∈ [0,1], y ∈ [0,1] (3 levels each)
mv_lut = LUT(:(x+y), [(:x, 0.0:0.5:1.0), (:y, 0.0:0.5:1.0)])

# Export Verilog with per-variable address buses
vlog = export_verilog(mv_lut, bits=8, fn_name="add")
# Generates: module lut_add_bits8(input [1:0] x, input [1:0] y, clk, output [7:0] data)

# Export VHDL
vhd = export_vhdl(mv_lut, bits=8, fn_name="add")

# Generate testbench with per-variable drive task
tb = export_testbench(mv_lut, bits=8)
```

### CORDIC-based LUTs

For higher precision or when no closed-form function is available, use CORDIC to generate
reference values:

```julia
using LUTify

# 16-bit CORDIC with 16 iterations for high-precision sin table
sinlut = LUT_cordic(sin, range(0.0, stop=2π, length=256), bits=12, n=16)

# Also available: cos, tan, sinh, cosh, exp, atan2
cosh_lut = LUT_cordic(cosh, range(0.0, stop=2.0, length=128), bits=10, n=12)
atan_lut = LUT_cordic(atan2, [(:y, -π:π/64:π), (:x, -π:π/64:π)], bits=10, n=12)
```
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
| `export_verilog(lut, bits, fn_name)` | Generate self-contained Verilog module string |

| `export_vhdl(lut, bits, fn_name)` | Generate VHDL entity/architecture string |

| `export_memfile(lut, path; format)` | Write memory init file (.hex, .mif, .coe, .txt) |

| `export_testbench(lut, bits, fn_name; tolerance, extra_cycles)` | Generate Verilog testbench with embedded reference values |



### Export to HDL (Verilog/VHDL)

Generate hardware description language modules directly from LUT objects:

```julia
using LUTify

sinlut = LUT_cordic(:sin, 0.0:(π/100):2π, 8, 16)

# Generate Verilog module
vlog = export_verilog(sinlut, 8, "sin")
open("sin_lut.v", "w") do f; write(f, vlog); end

# Generate VHDL entity
vhd = export_vhdl(sinlut, 8, "sin")
open("sin_lut.vhd", "w") do f; write(f, vhd); end

# Write memory initialization files for FPGA tools
export_memfile(sinlut, "sin_lut.hex")          # Intel/Altera HEX
export_memfile(sinlut, "sin_lut.mif"; format=:mif)   # Altera MIF
export_memfile(sinlut, "sin_lut.coe"; format=:coe)   # Xilinx COE
export_memfile(sinlut, "sin_lut.txt"; format=:txt)   # Plain text
```

The generated Verilog module has:
- `addr` input: address bus width = ⌈log₂(N)⌉ bits (N = LUT size)
- `clk` input: clock for registered output
- `data` output: quantized value (bits wide)

Standard float LUTs are automatically quantized from their value range to [0, 2^bits−1].

### Self-Contained Verilog Testbench

`export_testbench` generates a complete Verilog testbench that drives the DUT with all N address entries and compares against pre-computed reference values. The testbench embeds expected quantized outputs directly, so no external reference simulation is needed:

```julia
using LUTify

sinlut = LUT_cordic(:sin, 0.0:(π/50):2π, 8, 16)

# Generate a self-contained testbench
tb = export_testbench(sinlut, 8)
open("tb_sin.v", "w") do f; write(f, tb); end
```

The generated testbench includes:
- Parameterized DUT interface (`ADDR_W`, `BITS`, `N`)
- Embedded reference values as binary constants (`expected[00000000] = 8'b...`)
- Clock generation and sequential address sweep
- Per-entry comparison with ULP error tracking
- `$display` summary report with PASS/FAIL result and `$finish`

**Parameters:**
| Name | Default | Description |
|---|---|---|
| `lut` | — | LUT object to testbench |
| `bits` | 8 | Quantization bit width for the testbench DUT |
| `fn_name` | "lut" | Module name suffix |
| `tolerance` | 1.0 | Allowed mismatch in ULP (quantization steps) |
| `extra_cycles` | 4 | Extra clock cycles holding last address (stability check) |

The testbench outputs a summary like:
```
========================================
Testbench: tb_sin_bits8
DUT:       lut_sin_bits8 (N=101, BITS=8)
Cycles:    205
Errors:    0 / 101
Max err:   0 ULP
RESULT: PASS -- all N entries match reference
========================================
```

## TODO

- [x] CORDIC support (sin, cos, tan, atan2)
- [x] Hyperbolic CORDIC (sinh, cosh, exp)
- [x] Export lookup tables to HDL (Verilog/VHDL)
- [x] Self-contained Verilog testbench generation
- [x] Full test coverage (46 tests)
