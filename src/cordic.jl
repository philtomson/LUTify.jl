##########################################################
# LUTify — CORDIC algorithm support
# Generate lookup tables and evaluate trig functions via CORDIC
#
# CORDIC (COordinate Rotation Digital Computer) is an iterative
# algorithm that computes trigonometric functions using only
# shifts and adds — ideal for hardware implementation.
##########################################################

export cordic_angles, cordic_sin, cordic_cos, LUT_cordic

"""
    cordic_angles(n::Int=16) -> Vector{Float64}

Generate the CORDIC angle lookup table: `atan.(2 .^ (-0:(n-1)))`.

These are the precomputed angles used in each iteration of CORDIC rotation mode.
A 16-element table gives ~15 bits of precision; 24 elements gives ~23 bits.
"""
function cordic_angles(n::Int=16)
    [atan(2.0^(-i)) for i in 0:n-1]
end

"""
    _cordic_gain(n::Int=16) -> Float64

Return the CORDIC gain factor K = ∏ sec(atan(2^(-i))) for i=0..n-1.
The final vector magnitude after n iterations is scaled by K, so we divide by it.
"""
function _cordic_gain(n::Int=16)
    k_ref = Ref{Float64}(1.0)
    for i in 0:n-1
        k_ref[] *= sqrt(1.0 + 2.0^(-2i))
    end
    return k_ref[]
end

"""
    _cordic_core(θ::Float64, angles::Vector{Float64}, K::Float64) -> Tuple{Float64, Float64}

Core CORDIC rotation for |θ| ≤ π/4. Returns (sin(θ), cos(θ)).
"""
function _cordic_core(θ::Float64, angles::Vector{Float64}, K::Float64)
    x, y = 1.0, 0.0
    z = θ
    for i in eachindex(angles)
        shift = 2.0^(-(i-1))
        if z >= 0
            x, y = x - y * shift, y + x * shift
            z -= angles[i]
        else
            x, y = x + y * shift, y - x * shift
            z += angles[i]
        end
    end
    return y / K, x / K
end

"""
    cordic_sin(θ::Float64, n::Int=16) -> Float64

Compute sin(θ) using CORDIC rotation mode with `n` iterations.
Handles the full range [-∞, +∞] via quadrant reduction to [-π/4, π/4].

The max absolute error for common iteration counts:
  - 8 iters  → ~7×10⁻³
  - 12 iters → ~4×10⁻⁴
  - 16 iters → ~3×10⁻⁵
  - 20 iters → ~2×10⁻⁶
"""
function cordic_sin(θ::Float64, n::Int=16)
    angles = cordic_angles(n)
    K      = _cordic_gain(n)

    # Normalize to [0, 2π)
    θ = mod(θ, 2π)

    if θ <= π/4
        s, _ = _cordic_core(θ, angles, K)
        return s
    elseif θ <= 3π/4
        # sin(θ) = cos(θ - π/2), and (θ-π/2) ∈ [-π/4, π/4]
        _, c = _cordic_core(θ - π/2, angles, K)
        return c
    elseif θ <= 5π/4
        # sin(θ) = -sin(θ - π), and (θ-π) ∈ [-π/4, π/4]
        s, _ = _cordic_core(θ - π, angles, K)
        return -s
    else
        # sin(θ) = -cos(θ - 3π/2), and (θ-3π/2) ∈ [-π/4, π/4]
        _, c = _cordic_core(θ - 3π/2, angles, K)
        return -c
    end
end

"""
    cordic_sin(θ::Real, n::Int=16) -> Float64

Convert `θ` to Float64 and call `cordic_sin(Float64, Int)`.
"""
function cordic_sin(θ::Real, n::Int=16)
    return cordic_sin(Float64(θ), n)
end

"""
    cordic_cos(θ::Float64, n::Int=16) -> Float64

Compute cos(θ) using CORDIC rotation mode with `n` iterations.
Uses the identity cos(θ) = sin(θ + π/2) and reuses `cordic_sin`.
"""
function cordic_cos(θ::Float64, n::Int=16)
    return cordic_sin(θ + π/2, n)
end

"""
    cordic_cos(θ::Real, n::Int=16) -> Float64

Convert `θ` to Float64 and call `cordic_cos(Float64, Int)`.
"""
function cordic_cos(θ::Real, n::Int=16)
    return cordic_cos(Float64(θ), n)
end

"""
    LUT_cordic(fn::Symbol, r::StepRangeLen, bits::Int=8, n::Int=16) -> LUT{Vector{Float64}, StepRangeLen, Function}

Build a lookup table using CORDIC as the high-precision reference generator.
Returns a `LUT` object with float values in [0, 2^(bits-1)-1] (quantized from [-1, 1]).

Arguments:
  - `fn`: the symbol `:sin`, `:cos`, or `:tan`
  - `r`: the step range over which to sample
  - `bits`: output bit-width (default 8)
  - `n`: CORDIC iteration count (default 16)

Example:
```julia
sinlut = LUT_cordic(:sin, 0.0:(π/100):2π, 8, 16)
value = sinlut(π/4)
```
"""
function LUT_cordic(fn::Symbol, r::StepRangeLen, bits::Int=8, n::Int=16)
    if bits < 1 || bits > 32
        error("bits must be between 1 and 32")
    end

    scale = 2^bits - 1
    lut_vals = Vector{Float64}(undef, length(r))

    for (i, x) in enumerate(r)
        val = if fn === :sin
            cordic_sin(Float64(x), n)
        elseif fn === :cos
            cordic_cos(Float64(x), n)
        elseif fn === :tan
            t = cordic_sin(Float64(x), n) / cordic_cos(Float64(x), n)
            max(-1.0, min(1.0, t))  # clamp tan to [-1, 1] for quantization
        else
            error("Unsupported function: \$(fn). Use :sin, :cos, or :tan")
        end
        # Quantize from [-1, 1] to [0, scale]
        lut_vals[i] = (val + 1.0) / 2.0 * scale
    end

    return LUT(x -> x, r, lut_vals)
end
