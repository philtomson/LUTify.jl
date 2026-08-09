using Test
using LUTify

println("=== Testing CORDIC ===")

# Test cordic_angles
@test length(cordic_angles(4)) == 4
@test isapprox(cordic_angles(4)[1], atan(1.0), rtol=1e-10)
println("cordic_angles: PASS")

# Test cordic_sin accuracy at key points
@test isapprox(cordic_sin(0.0, 16), sin(0.0), atol=1e-4)
@test isapprox(cordic_sin(π/6, 16), sin(π/6), atol=1e-4)
@test isapprox(cordic_sin(π/4, 16), sin(π/4), atol=1e-4)
@test isapprox(cordic_sin(π/2, 16), sin(π/2), atol=1e-4)
@test isapprox(cordic_sin(π, 16), sin(π), atol=1e-4)
@test isapprox(cordic_sin(3π/2, 16), sin(3π/2), atol=1e-4)
@test isapprox(cordic_sin(2π, 16), sin(2π), atol=1e-4)
println("cordic_sin accuracy: PASS")

# Test cordic_cos
@test isapprox(cordic_cos(0.0, 16), cos(0.0), atol=1e-4)
@test isapprox(cordic_cos(π/3, 16), cos(π/3), atol=1e-4)
println("cordic_cos accuracy: PASS")

# Test iteration count vs error bound
for n in [4, 8, 12, 16]
    @test LUTify._cordic_gain(n) > 0.5 && LUTify._cordic_gain(n) < 2.0
end
println("CORDIC gain: PASS")

# Test LUT_cordic construction
sinlut = LUT_cordic(:sin, 0.0:(π/100):2π, 8, 16)
@test sinlut.r[1] ≈ 0.0
@test length(sinlut.lut) == length(0.0:(π/100):2π)
println("LUT_cordic construction: PASS")

# Test that values are in valid range [0, 255] for 8-bit
@test all(v -> 0 <= v <= 255, sinlut.lut)
println("LUT_cordic value range: PASS")

# Test existing LUT functionality still works
identLut = LUT(x -> x, 0.0:0.5:10.0)
@test isapprox(identLut(2.5), 2.5, atol=0.0)
println("Existing LUT: PASS")

sinlut_old = LUT(sin, 0.0:(π/100):2π)
@test length(sinlut_old.lut) == length(0.0:(π/100):2π)
println("Existing sin LUT: PASS")

# Multi-var LUT via LUT constructor (not build_lut directly)
exprlut = LUT(:(x+y+z), [(:x, 0.0:0.1:10.0), (:y, 0.0:0.1:10.0), (:z, 0.0:0.1:10.0)])
@test exprlut.lut[LUTify.get_idx(exprlut, Dict(:x=>4.0, :y=>3.0, :z=>1.0))] ≈ 8.0
println("Multi-var LUT: PASS")

# Test CORDIC vs direct sin on the generated table
max_err = maximum(abs, sinlut.lut .- ((sin.(collect(sinlut.r)) .+ 1.0) ./ 2.0 .* 255))
@test max_err < 1.0
println("CORDIC vs float sin table comparison: PASS (max diff = ", max_err, ")")

# Test cos LUT
coslut = LUT_cordic(:cos, 0.0:(π/100):2π, 8, 16)
@test length(coslut.lut) == length(0.0:(π/100):2π)
@test all(v -> 0 <= v <= 255, coslut.lut)
println("LUT_cordic(:cos): PASS")

# Test tan LUT (clamped)
tanlut = LUT_cordic(:tan, 0.0:(π/100):(π/2 - 0.01), 8, 16)
@test length(tanlut.lut) > 0
@test all(v -> 0 <= v <= 255, tanlut.lut)
println("LUT_cordic(:tan): PASS")

# Test different bit widths
for bits in [4, 8, 16]
    lut = LUT_cordic(:sin, 0.0:(π/50):π, bits, 16)
    max_val = 2^bits - 1
    @test all(v -> 0 <= v <= max_val, lut.lut)
end
println("Different bit widths: PASS")

# Test error decreases with more iterations
err_8  = maximum(abs, cordic_sin.(collect(0.0:π/100:2π), Ref(8)) .- sin.(collect(0.0:π/100:2π)))
err_16 = maximum(abs, cordic_sin.(collect(0.0:π/100:2π), Ref(16)) .- sin.(collect(0.0:π/100:2π)))
@test err_16 < err_8
println("More iterations → less error: PASS (8iter=", round(err_8, sigdigits=3), ", 16iter=", round(err_16, sigdigits=3), ")")

# ──────────────────────────────────────────────────────
# Hyperbolic CORDIC tests
# ──────────────────────────────────────────────────────
println()
println("=== Testing Hyperbolic CORDIC ===")

# Test cordic_cosh at key points
@test isapprox(cordic_cosh(0.0, 16), cosh(0.0), atol=1e-4)
@test isapprox(cordic_cosh(0.5, 16), cosh(0.5), atol=1e-3)
@test isapprox(cordic_cosh(1.0, 16), cosh(1.0), atol=1e-3)
@test isapprox(cordic_cosh(-1.0, 16), cosh(-1.0), atol=1e-3)
println("cordic_cosh accuracy: PASS")

# Test cordic_sinh at key points
@test isapprox(cordic_sinh(0.0, 16), sinh(0.0), atol=1e-4)
@test isapprox(cordic_sinh(0.5, 16), sinh(0.5), atol=1e-3)
@test isapprox(cordic_sinh(1.0, 16), sinh(1.0), atol=1e-3)
@test isapprox(cordic_sinh(-1.0, 16), sinh(-1.0), atol=1e-3)
println("cordic_sinh accuracy: PASS")

# Test cordic_exp
@test isapprox(cordic_exp(0.0, 16), exp(0.0), atol=1e-4)
@test isapprox(cordic_exp(0.5, 16), exp(0.5), atol=1e-3)
@test isapprox(cordic_exp(1.0, 16), exp(1.0), atol=1e-3)
@test isapprox(cordic_exp(-1.0, 16), exp(-1.0), atol=1e-3)
println("cordic_exp accuracy: PASS")

# Test identity: cosh² - sinh² = 1
for z in [-2.0, -1.0, 0.0, 0.5, 1.0, 2.0]
    c = cordic_cosh(z, 16)
    s = cordic_sinh(z, 16)
    @test isapprox(c^2 - s^2, 1.0, atol=1e-3)
end
println("cosh² - sinh² = 1 identity: PASS")

# Test exp(x) = cosh(x) + sinh(x)
for z in [-2.0, -1.0, 0.0, 0.5, 1.0, 2.0]
    @test isapprox(cordic_exp(z, 16), cordic_cosh(z, 16) + cordic_sinh(z, 16), atol=1e-3)
end
println("exp = cosh + sinh identity: PASS")

# Test error decreases with more iterations for hyperbolic
err_8_c  = maximum(abs, [cordic_cosh(z, 8) - cosh(z) for z in -2.0:0.1:2.0])
err_16_c = maximum(abs, [cordic_cosh(z, 16) - cosh(z) for z in -2.0:0.1:2.0])
@test err_16_c < err_8_c
println("Hyperbolic: more iterations → less error: PASS")

# ──────────────────────────────────────────────────────
# atan2 CORDIC tests
# ──────────────────────────────────────────────────────
println()
println("=== Testing atan2 CORDIC ===")

@test isapprox(cordic_atan2(0.0, 1.0, 16), atan(0.0, 1.0), atol=1e-3)
@test isapprox(cordic_atan2(1.0, 0.0, 16), atan(1.0, 0.0), atol=1e-3)
@test isapprox(cordic_atan2(-1.0, 0.0, 16), atan(-1.0, 0.0), atol=1e-3)
@test isapprox(cordic_atan2(0.0, -1.0, 16), atan(0.0, -1.0), atol=1e-3)
@test isapprox(cordic_atan2(1.0, 1.0, 16), atan(1.0, 1.0), atol=1e-2)
@test isapprox(cordic_atan2(-1.0, 1.0, 16), atan(-1.0, 1.0), atol=1e-2)
@test isapprox(cordic_atan2(-1.0, -1.0, 16), atan(-1.0, -1.0), atol=1e-2)
@test isapprox(cordic_atan2(1.0, -1.0, 16), atan(1.0, -1.0), atol=1e-2)
println("cordic_atan2 key points: PASS")

# Test atan2 consistency with sin/cos
for θ in 0.0:π/8:2π
    y = cordic_sin(θ, 16)
    x = cordic_cos(θ, 16)
    recovered = cordic_atan2(y, x, 16)
    # Normalize difference to [-π, π]
    diff = recovered - θ
    while diff > π; diff -= 2π; end
    while diff < -π; diff += 2π; end
    @test abs(diff) < 0.3  # generous tolerance for atan2
end
println("atan2 consistency with sin/cos: PASS")
# ──────────────────────────────────────────────
# Testing HDL Export
# ──────────────────────────────────────────────
@testset "HDL Export" begin
    @testset "Verilog generation" begin
        sinlut = LUT_cordic(:sin, 0.0:(π/100):2π, 8, 16)
        vlog = export_verilog(sinlut, 8, "sin")

        @test occursin("module lut_sin_bits8(", vlog)
        @test occursin("input  wire [7:0] addr", vlog)
        @test occursin("output reg  [7:0]     data", vlog)
        @test occursin("reg [7:0] lut [0:199];", vlog)
        @test occursin("8'b01111111;", vlog)   # index 0 = 127 = 0x7f
        @test occursin("8'b10000100;", vlog)  # index 1 = 132 = 0x84
    end

    @testset "VHDL generation" begin
        sinlut = LUT_cordic(:sin, 0.0:(π/100):2π, 8, 16)
        vhd = export_vhdl(sinlut, 8, "sin")

        @test occursin("entity lut_sin_8bit is", vhd)
        @test occursin("addr : in  std_logic_vector(7 downto 0);", vhd)
        @test occursin("data : out std_logic_vector(7 downto 0)", vhd)
        @test occursin("constant lut : lut_array_t := (", vhd)
        @test occursin("x\"7f\",", vhd)   # index 0 = 127 = 0x7f
        @test occursin("x\"84\",", vhd)   # index 1 = 132 = 0x84
    end

    @testset "Memory files" begin
        sinlut = LUT_cordic(:sin, 0.0:(π/100):2π, 8, 16)

        export_memfile(sinlut, "/tmp/test_lut.hex")
        hex_content = read("/tmp/test_lut.hex", String)
        @test startswith(hex_content, "% 8\n")
        @test occursin("7f\n", hex_content)   # first value = 127
        @test occursin("84\n", hex_content)   # second value = 132

        export_memfile(sinlut, "/tmp/test_lut.mif"; format=:mif)
        mif_content = read("/tmp/test_lut.mif", String)
        @test occursin("DEPTH = 200;", mif_content)
        @test occursin("WIDTH = 8;", mif_content)

        export_memfile(sinlut, "/tmp/test_lut.coe"; format=:coe)
        coe_content = read("/tmp/test_lut.coe", String)
        @test occursin("memory_initialization_radix=10;", coe_content)
        @test occursin("    127,", coe_content)   # first value

        export_memfile(sinlut, "/tmp/test_lut.txt"; format=:txt)
        txt_content = read("/tmp/test_lut.txt", String)
        lines_txt = split(chomp(txt_content), "
")
        @test length(lines_txt) == 200
        @test parse(Int, lines_txt[1]) == 127

        rm("/tmp/test_lut.hex"; force=true)
        rm("/tmp/test_lut.mif"; force=true)
        rm("/tmp/test_lut.coe"; force=true)
        rm("/tmp/test_lut.txt"; force=true)
    end

    @testset "Standard LUT quantization" begin
        stdlut = LUT(sin, 0.0:(π/50):2π)
        vlog = export_verilog(stdlut, 8, "sin_std")
        @test occursin("module lut_sin_std_bits8(", vlog)
        @test occursin("8'b10000000;", vlog)   # sin(0) = 0 → quantized to ~128
    end

    @testset "Different bit widths" begin
        sinlut = LUT_cordic(:sin, 0.0:(π/100):2π, 8, 16)
        vlog_4bit = export_verilog(sinlut, 4, "sin")
        @test occursin("reg [3:0] lut", vlog_4bit)
        vlog_16bit = export_verilog(sinlut, 16, "sin")
        @test occursin("reg [15:0] lut", vlog_16bit)
    end

    @testset "Invalid bits throws error" begin
        sinlut = LUT_cordic(:sin, 0.0:(π/100):2π, 8, 16)
        @test_throws ErrorException export_verilog(sinlut, 0, "bad")
        @test_throws ErrorException export_verilog(sinlut, 33, "bad")

    @testset "Testbench generation" begin
        # Basic testbench for sin LUT
        sinlut = LUT_cordic(:sin, 0.0:(π/100):2π, 8, 16)
        tb = export_testbench(sinlut; extra_cycles=0)

        @test occursin("module tb_lut_bits8;", tb)
        @test occursin("parameter N      = ", tb)
        @test occursin("parameter BITS   = 8;", tb)
        @test occursin("ADDR_W-1:0", tb)  # parameterized address width
        @test occursin("BITS-1:0]", tb)  # parameterized data width
        @test occursin("dut (", tb)
        @test occursin("\$finish;", tb)

        # Check that expected values are embedded
        @test occursin("expected[00000000] = 8'b", tb)
        @test occursin("expected[00000199] = 8'b", tb)
    end

    @testset "Testbench with different bit widths" begin
        sinlut = LUT_cordic(:sin, 0.0:(π/50):2π, 8, 16)

        # 4-bit testbench
        tb_4bit = export_testbench(sinlut, 4; extra_cycles=0)
        @test occursin("parameter BITS   = 4;", tb_4bit)
        @test occursin("ADDR_W", tb_4bit)

        # 16-bit testbench
        tb_16bit = export_testbench(sinlut, 16; extra_cycles=0)
        @test occursin("parameter BITS   = 16;", tb_16bit)
        @test occursin("ADDR_W", tb_16bit)
    end

    @testset "Testbench with cos and tan" begin
        # Cos testbench
        r = range(0.0, stop=2π, length=64)
        coslut = LUT_cordic(:cos, r, 8)
        tb_cos = export_testbench(coslut; extra_cycles=0)
        @test occursin("module tb_lut_bits8;", tb_cos)

        # Tan testbench (use smaller range to avoid infinities)
        tanlut = LUT_cordic(:tan, -π/4:(π/64):π/4, 8)
        tb_tan = export_testbench(tanlut; extra_cycles=0)
        @test occursin("module tb_lut_bits8;", tb_tan)
    end

    @testset "Testbench with standard LUT" begin
        stdlut = LUT(sin, 0.0:(π/50):2π)
        tb = export_testbench(stdlut; extra_cycles=0)
        @test occursin("module tb_lut_bits8;", tb)
        @test occursin("\$finish;", tb)
    end

    @testset "Testbench with extra cycles" begin
        sinlut = LUT_cordic(:sin, 0.0:(π/100):2π, 8, 16)
        tb = export_testbench(sinlut; extra_cycles=4)

        # Should contain stability check code
        @test occursin("extra cycles", tb)
        @test occursin("stable-check", tb)
    end
    end
end

# ──────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────
println()

# ============================================
# Multi-var LUT HDL export tests
# ============================================
println("\n=== Testing Multi-var HDL Export ===")

mv_lut = LUT(:(x+y), [(:x, 0.0:0.5:1.0), (:y, 0.0:0.5:1.0)])

# Test Verilog generation
vlog_mv = export_verilog(mv_lut, 8, "add")
@test length(vlog_mv) > 0
@test occursin("module lut_add_bits8", vlog_mv)
@test occursin("input  wire [1:0]     x", vlog_mv)
@test occursin("input  wire [1:0]     y", vlog_mv)
@test occursin("wire [3:0] addr = x * 3 + y * 1", vlog_mv)
@test occursin("lut[0000]", vlog_mv)
println("Multi-var Verilog export: PASS")

# Test VHDL generation
vhd_mv = export_vhdl(mv_lut, 8, "add")
@test length(vhd_mv) > 0
@test occursin("entity lut_add_8bit", vhd_mv)
@test occursin("x : in  std_logic_vector(1 downto 0)", vhd_mv)
@test occursin("y : in  std_logic_vector(1 downto 0)", vhd_mv)
@test occursin("signal addr : std_logic_vector(3 downto 0)", vhd_mv)
println("Multi-var VHDL export: PASS")

# Test memfile generation
export_memfile(mv_lut, "/tmp/mv_test.hex"; bits=8, format=:hex)
@test isfile("/tmp/mv_test.hex")
open("/tmp/mv_test.hex") do f
    hex_content = read(f, String)
    @test startswith(hex_content, "% 8")
    # Multi-var LUT entries are single bytes in compact format
    @test contains(hex_content, "01")
end
println("Multi-var memfile export: PASS")

# Test single-var still works after multi-var changes
sinlut = LUT(sin, range(0.0, stop=2π, length=64))
vlog_sv = export_verilog(sinlut, 8, "sin")
@test occursin("input  wire [5:0] addr", vlog_sv)
@test !occursin("input  wire [1:0]     x", vlog_sv)
println("Single-var Verilog unchanged: PASS")

vhd_sv = export_vhdl(sinlut, 8, "sin")
@test occursin("addr : in  std_logic_vector(5 downto 0)", vhd_sv)
println("Single-var VHDL unchanged: PASS")

println("All tests passed!")
