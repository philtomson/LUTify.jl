#!/usr/bin/env julia
#
# examples/full_pipeline.jl
#
# End-to-end demo: create a LUT, export to Verilog + testbench, and run simulation.

using LUTify

println("=== Full Pipeline Demo: sin LUT from creation to simulation ===\n")

OUT = joinpath(@__DIR__, "output")
isdir(OUT) || mkdir(OUT)

# ---- Step 1: Create the LUT ----
println("Step 1: Creating LUT...")
sinlut = LUT(sin, range(0.0, stop=2π, length=64))
println("       $(length(sinlut.lut))-entry sin table, range [0, 2π]")

# ---- Step 2: Export Verilog module ----
println("\nStep 2: Exporting Verilog...")
vlog = export_verilog(sinlut, 8, "sin")
open(joinpath(OUT, "sin_8bit.v"), "w") do f; write(f, vlog); end
println("       Written: $(joinpath(OUT, "sin_8bit.v"))")

# ---- Step 3: Export testbench ----
println("\nStep 3: Generating self-contained testbench...")
tb = export_testbench(sinlut, 8, "sin")
open(joinpath(OUT, "tb_sin_8bit.v"), "w") do f; write(f, tb); end
println("       Written: $(joinpath(OUT, "tb_sin_8bit.v"))")

# ---- Step 4: Also export a low-bitwidth version for comparison ----
println("\nStep 4: Exporting 4-bit version...")
sinlut_4bit = LUT(sin, range(0.0, stop=2π, length=16))
open(joinpath(OUT, "sin_4bit.v"), "w") do f; write(f, export_verilog(sinlut_4bit, 4, "sin")); end
open(joinpath(OUT, "tb_sin_4bit.v"), "w") do f; write(f, export_testbench(sinlut_4bit, 4, "sin")); end
println("       Written: output/sin_4bit.v + output/tb_sin_4bit.v")

# ---- Step 5: Run simulations with iverilog (if available) ----
println("\nStep 5: Running iverilog simulations...")
iverilog_bin = "/home/phil/bin/oss-cad-suite/bin/iverilog"
vvp_bin      = "/home/phil/bin/oss-cad-suite/bin/vvp"
has_iverilog = isfile(iverilog_bin) && isfile(vvp_bin)
if has_iverilog
    for (name, vlog_f, tb_f) in [
            ("sin_8bit", "sin_8bit.v", "tb_sin_8bit.v"),
            ("sin_4bit",  "sin_4bit.v", "tb_sin_4bit.v")]
        try
            r1 = run(`$iverilog_bin -o $name $(joinpath(OUT, vlog_f)) $(joinpath(OUT, tb_f))`)
            if r1.exitcode == 0
                run(`$vvp_bin $name`)
            end
        catch e
            println("  Simulation of $name failed: ", e)
        end
    end
else
    println("  (iverilog not found — skipping simulation)")
end

println("\n=== Demo complete! ===")
println("Generated files in: $OUT/")
