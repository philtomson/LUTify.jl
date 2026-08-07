
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

println()
println("All tests passed!")
