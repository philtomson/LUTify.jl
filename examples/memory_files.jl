#!/usr/bin/env julia
#
# examples/memory_files.jl
#
# Demonstrates exporting LUT data to various memory file formats used by
# FPGA synthesis tools (Intel/Altera, Xilinx).

using LUTify

println("=== Example 4: Memory File Exports ===\n")

coslut = LUT(cos, range(0.0, stop=2π, length=32))
println("Created cos LUT with $(length(coslut.lut)) entries\n")

# ---- Intel/Altera HEX format ----
hex_path = joinpath(@__DIR__, "cos_lut.hex")
export_memfile(coslut, hex_path; bits=10, format=:hex)
println("Exported cos_lut.hex (Intel/Altera HEX)")
open(hex_path) do f
    println("  First 5 lines:")
    for line in readlines(f)[1:5]
        println("    ", line)
    end
end

# ---- Xilinx MIF format ----
mif_path = joinpath(@__DIR__, "cos_lut.mif")
export_memfile(coslut, mif_path; bits=10, format=:mif)
println("\nExported cos_lut.mif (Xilinx MIF)")
open(mif_path) do f
    println("  First 5 lines:")
    for line in readlines(f)[1:5]
        println("    ", line)
    end
end

# ---- Xilinx COE format ----
coe_path = joinpath(@__DIR__, "cos_lut.coe")
export_memfile(coslut, coe_path; bits=10, format=:coe)
println("\nExported cos_lut.coe (Xilinx COE)")
open(coe_path) do f
    println("  First 5 lines:")
    for line in readlines(f)[1:5]
        println("    ", line)
    end
end

# ---- Plain text format ----
txt_path = joinpath(@__DIR__, "cos_lut.txt")
export_memfile(coslut, txt_path; bits=10, format=:txt)
println("\nExported cos_lut.txt (plain decimal)")
open(txt_path) do f
    content = read(f, String)
    vals = split(chomp(content), r"\s+")
    println("  First 5 values: ", join(vals[1:min(5,end)], ", "))
end

println("\nThese files can be loaded directly into FPGA block RAM or ROM:")
# Use string concatenation to avoid Julia interpolation of Verilog $
q1 = "ram_1port.v with \$readmemh(\"cos_lut.hex\", ram)"
println("  Intel Quartus:   ", q1)
q2 = "\$readmemh(\"cos_lut.mif\", ram);"
println("  Xilinx Vivado:   ", q2)
