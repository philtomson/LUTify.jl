#!/usr/bin/env julia
#
# examples/multivar_lut.jl
#
# Demonstrates multi-var lookup tables with per-variable address buses.
# The addressing follows a row-major stride scheme matching get_idx.

using LUTify

println("=== Example 3: Multi-Variable Lookup Table ===\n")

# ---- 2-variable table: z = x + y ----
mv_lut = LUT(:(x+y), [(:x, 0.0:0.5:1.0), (:y, 0.0:0.5:1.0)])
println("Created $(length(mv_lut.lut))-entry 2-var LUT (x+y)")
println("  x ∈ [0.0, 1.0] with 3 levels")
println("  y ∈ [0.0, 1.0] with 3 levels")
println("  Address mapping: flat = x_idx * 3 + y_idx")

# Print the full table
println("\nLUT contents (flat index → value):")
for i in 1:length(mv_lut.lut)
    idx_y = (i - 1) % 3
    idx_x = (i - 1) ÷ 3
    x_val = first(mv_lut.r[1][2]) + idx_x * step(mv_lut.r[1][2])
    y_val = first(mv_lut.r[2][2]) + idx_y * step(mv_lut.r[2][2])
    println("  lut[$(lpad(i-1, 2))]: x=$x_val, y=$y_val → $(mv_lut.lut[i])")
end

# ---- Export Verilog with per-variable address buses (positional args) ----
verilog = export_verilog(mv_lut, 8, "add")
open(joinpath(@__DIR__, "multivar_add.v"), "w") do f
    write(f, verilog)
end
println("\nExported multivar_add.v")
println("  Ports: input [1:0] x, input [1:0] y, clk, output [7:0] data")
println("  Address: wire [3:0] addr = x * 3 + y * 1")

# ---- Export VHDL ----
vhdl = export_vhdl(mv_lut, 8, "add")
open(joinpath(@__DIR__, "multivar_add.vhd"), "w") do f
    write(f, vhdl)
end
println("Exported multivar_add.vhd")

# ---- Generate testbench ----
testbench = export_testbench(mv_lut, 8, "add")
open(joinpath(@__DIR__, "tb_multivar_add.v"), "w") do f
    write(f, testbench)
end
println("Generated tb_multivar_add.v")

# ---- 3-variable example: z = x*y + y ----
println("\n--- 3-variable LUT: z = x*y + y ---")
mv3_lut = LUT(:(x*y+y), [(:x, 0.0:1.0:2.0), (:y, 0.0:1.0:2.0)])
println("Created $(length(mv3_lut.lut))-entry 3-var LUT")

verilog3 = export_verilog(mv3_lut, 8, "xy_plus_y")
open(joinpath(@__DIR__, "multivar_3var.v"), "w") do f
    write(f, verilog3)
end
println("Exported multivar_3var.v (ports: input [1:0] x, input [1:0] y, clk, output [7:0] data)")

testbench3 = export_testbench(mv3_lut, 8, "xy_plus_y")
open(joinpath(@__DIR__, "tb_multivar_3var.v"), "w") do f
    write(f, testbench3)
end
println("Generated tb_multivar_3var.v")

println("\nTo simulate: iverilog -o tb_multivar_add tb_multivar_add.v multivar_add.v && vvp tb_multivar_add")
