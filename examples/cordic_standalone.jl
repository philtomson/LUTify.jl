#!/usr/bin/env julia
#
# examples/cordic_standalone.jl
#
# Demonstrates using CORDIC as a standalone evaluator (not for LUT generation).
# Useful when you need trig/hyperbolic functions in resource-constrained environments.

using LUTify

println("=== Example 5: Standalone CORDIC Evaluation ===\n")

# ---- sin/cos via CORDIC ----
println("--- sin accuracy ---")
for n_iters in [4, 8, 12, 16]
    max_err = 0.0
    for θ in range(0.0, stop=2π, length=100)
        ref = sin(θ)
        approx = cordic_sin(θ, n_iters)
        err = abs(approx - ref)
        max_err = max(max_err, err)
    end
    # Use string concatenation to avoid nested interpolation issues
    prec = min(6, n_iters)
    println("  $n_iters iterations: max error = $(round(max_err; digits=prec))")
end

# ---- hyperbolic functions ----
println("\n--- hyperbolic functions (8 iterations) ---")
for z in [0.0, 0.5, 1.0, 1.5, 2.0]
    sinh_val = cordic_sinh(z, 8)
    cosh_val = cordic_cosh(z, 8)
    exp_val  = cordic_exp(z, 8)
    println("  z=$z: sinh=$(round(sinh_val,digits=4)), cosh=$(round(cosh_val,digits=4)), " *
            "exp=$(round(exp_val,digits=4))  (exact: sinh=$(round(sinh(z),digits=4)), " *
            "cosh=$(round(cosh(z),digits=4)), exp=$(round(exp(z),digits=4)))")
end

# ---- atan2 via CORDIC ----
println("\n--- atan2 key points ---")
for (y, x) in [(1.0, 0.0), (1.0, 1.0), (0.0, 1.0), (-1.0, 0.0), (1.0, -1.0)]
    approx = cordic_atan2(y, x, 12)
    exact  = atan(y, x)
    println("  atan2($y, $x): CORDIC=$(round(approx,digits=4)), " *
            "Julia=$(round(exact,digits=4))")
end

println("\nNote: CORDIC is iterative and uses only shifts/adds -- ideal for FPGA/ASIC.")
