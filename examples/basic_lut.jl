#!/usr/bin/env julia
#
# examples/basic_lut.jl
#
# Demonstrates creating a basic lookup table from sin(), exporting it to
# Verilog, and simulating it with iverilog.

using LUTify

println("=== Example 1: Basic Single-Variable LUT ===\n")

# ---- Create a sine LUT ----
sinlut = LUT(sin, range(0.0, stop=2π, length=64))
println("Created sin LUT with $(length(sinlut.lut)) entries")
println("Range: [$(first(sinlut.r)), $(last(sinlut.r))]")

# Look up a value directly from the table (nearest-neighbor)
val = sinlut(π/4)
println("sinlut(π/4) ≈ $val  (exact: $(sin(π/4)))")

# ---- Export to Verilog (positional args: lut, bits, fn_name) ----
verilog_code = export_verilog(sinlut, 8, "sin")
open(joinpath(@__DIR__, "basic_sin.v"), "w") do f
    write(f, verilog_code)
end
println("\nExported basic_sin.v (64 entries, 8-bit data)")

# ---- Export to VHDL ----
vhdl_code = export_vhdl(sinlut, 8, "sin")
open(joinpath(@__DIR__, "basic_sin.vhd"), "w") do f
    write(f, vhdl_code)
end
println("Exported basic_sin.vhd")

# ---- Generate and run a self-contained testbench ----
testbench = export_testbench(sinlut, 8, "sin")
open(joinpath(@__DIR__, "tb_basic_sin.v"), "w") do f
    write(f, testbench)
end
println("Generated tb_basic_sin.v")

println("\nTo simulate: iverilog -o tb_basic_sin tb_basic_sin.v basic_sin.v && vvp tb_basic_sin")
