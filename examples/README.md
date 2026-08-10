# LUTify.jl Examples

Standalone Julia scripts demonstrating different ways to use LUTify.

## Running Examples

Each example is a self-contained Julia script:

```bash
julia --project examples/basic_lut.jl
julia --project examples/cordic_lut.jl
julia --project examples/multivar_lut.jl
julia --project examples/memory_files.jl
julia --project examples/cordic_standalone.jl
julia --project examples/full_pipeline.jl
```

## What Each Example Shows

| File | Description |
|------|-------------|
| `basic_lut.jl` | Create a sin LUT, export to Verilog + VHDL, run testbench simulation |
| `cordic_lut.jl` | High-precision CORDIC-based LUT generation with accuracy analysis |
| `multivar_lut.jl` | Multi-variable LUTs (2-var and 3-var) with per-port address buses |
| `memory_files.jl` | Export to Intel/Altera HEX, Xilinx MIF/COE, and plain text formats |
| `cordic_standalone.jl` | Use CORDIC as a standalone evaluator (sin, cos, sinh, cosh, exp, atan2) |
| `full_pipeline.jl` | End-to-end workflow: LUT → Verilog → testbench → iverilog simulation |

## Prerequisites

- Julia 1.10+
- `iverilog` and `vvp` (for the full pipeline demo; install with `apt install iverilog`)
- Install dependencies: `julia --project -e 'using Pkg; Pkg.instantiate()'`
