#!/usr/bin/env julia
#
# examples/cordic_lut.jl
#
# Demonstrates using CORDIC to generate high-precision lookup tables,
# comparing quantized vs float reference values.

using LUTify

println("=== Example 2: CORDIC-based Lookup Tables ===\n")

# ---- High-precision sin table via CORDIC ----
sin_cordic = LUT_cordic(:sin, range(0.0, stop=2π, length=128), 12, 16)
println("CORDIC sin LUT: $(length(sin_cordic.lut)) entries, 12-bit data")

# Compute max error across full range
r = sin_cordic.r
max_err_val = foldl(max, 
    (abs(Float64(sin_cordic.lut[i]) - sin(first(r) + (i-1)*Float64(step(r)))) for i in 1:length(sin_cordic.lut));
    init=0.0)
println("\nMax absolute error over full range: $max_err_val")

# Show sample points
println("\nSample comparisons:")
for i in [1, 17, 33, 65, 97, length(sin_cordic.lut)]
    θ = first(r) + (i-1) * Float64(step(r))
    quantized = Float64(sin_cordic.lut[i])
    exact = sin(θ)
    println("  θ=$(round(θ, digits=3)): quantized=$(round(quantized, digits=6)), exact=$(round(exact, digits=6))")
end

# ---- cos table with fewer iterations ----
cos_cordic = LUT_cordic(:cos, range(0.0, stop=π/2, length=64), 8, 8)
println("\nCORDIC cos LUT: $(length(cos_cordic.lut)) entries, 8-bit data, 8 iterations")

# ---- Export to Verilog ----
verilog = export_verilog(sin_cordic, 12, "sin_precise")
open(joinpath(@__DIR__, "cordic_sin.v"), "w") do f
    write(f, verilog)
end
println("\nExported cordic_sin.v (128 entries, 12-bit)")

# ---- Generate testbench ----
testbench = export_testbench(sin_cordic, 12, "sin_precise")
open(joinpath(@__DIR__, "tb_cordic_sin.v"), "w") do f
    write(f, testbench)
end
println("Generated tb_cordic_sin.v")

println("\nTo simulate: iverilog -o tb_cordic_sin tb_cordic_sin.v cordic_sin.v && vvp tb_cordic_sin")
