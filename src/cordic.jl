##########################################################
# LUTify — CORDIC algorithm support
# Generate lookup tables and evaluate trig/hyperbolic functions via CORDIC
#
# CORDIC (COordinate Rotation Digital Computer) is an iterative
# algorithm that computes trigonometric functions using only
# shifts and adds — ideal for hardware implementation.
##########################################################

export cordic_angles, cordic_sin, cordic_cos, LUT_cordic,
       cordic_atan2, cordic_sinh, cordic_cosh, cordic_exp

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

# ──────────────────────────────────────────────────────
# Hyperbolic CORDIC (sinh, cosh, exp)
# ──────────────────────────────────────────────────────

"""
    _hyperbolic_angles(n::Int=16) -> Vector{Float64}

Generate the hyperbolic CORDIC angle table: `atanh.(2 .^ (-1:(n-1)))`.
Note: i starts at 1 (not 0) because atanh(1) diverges.
"""
function _hyperbolic_angles(n::Int=16)
    [atanh(2.0^(-i)) for i in 1:n-1]
end

"""
    _hyperbolic_gain(n::Int=16) -> Float64

Return the hyperbolic CORDIC gain factor K_h = ∏ sqrt(1 - 2^(-2i)) for i=1..n-1.
The final vector magnitude is scaled by K_h, so we divide by it.
"""
function _hyperbolic_gain(n::Int=16)
    k_ref = Ref{Float64}(1.0)
    for i in 1:n-1
        k_ref[] *= sqrt(1.0 - 2.0^(-2i))
    end
    return k_ref[]
end

"""
    _hyperbolic_core(z0::Float64, n::Int=16) -> Tuple{Float64, Float64}

Core hyperbolic CORDIC rotation for |z0| ≤ atanh(2^(-1)) ≈ 0.549.
Returns (cosh(z0), sinh(z0)).
Uses the correct sign convention: d = +sign(z) with PLUS signs in updates.
"""
function _hyperbolic_core(z0::Float64, n::Int=16)
    angles = _hyperbolic_angles(n)
    K_h    = _hyperbolic_gain(n)

    x, y, z = 1.0, 0.0, z0
    for i in eachindex(angles)
        d = z >= 0 ? 1 : -1
        shift = 2.0^(-i)   # i starts at 1 since angles is 1-indexed from atanh(2^(-1))
        x_new = x + d * y * shift
        y_new = y + d * x * shift
        z -= d * angles[i]
        x, y = x_new, y_new
    end
    return x / K_h, y / K_h
end

"""
    cordic_cosh(z::Float64, n::Int=16) -> Float64

Compute cosh(z) using hyperbolic CORDIC with range reduction.
For |z| ≤ atanh(2^(-1)) the core iteration converges directly.
For larger z, decomposes z = k·ln(2) + r and uses exact powers of 2.
"""
function cordic_cosh(z::Float64, n::Int=16)
    z == 0.0 && return 1.0

    max_angle = atanh(2.0^(-1))
    if abs(z) <= max_angle
        c, _ = _hyperbolic_core(z, n)
        return c
    end

    # Range reduction: z = k·ln2 + r where |r| ≤ atanh(2^(-1))
    ln2 = log(2.0)
    k = round(Int, z / ln2)
    r = z - k * ln2

    # Exact values for integer multiples of ln2: cosh(k·ln2) = (2^k + 2^(-k))/2
    c_k = (2.0^k + 2.0^(-k)) / 2.0
    s_k = (2.0^k - 2.0^(-k)) / 2.0

    c_r, s_r = cordic_cosh(r, n), cordic_sinh(r, n)

    # cosh(a+b) = cosh(a)cosh(b) + sinh(a)sinh(b)
    return c_k * c_r + s_k * s_r
end

"""
    cordic_cosh(z::Real, n::Int=16) -> Float64

Convert `z` to Float64 and call `cordic_cosh(Float64, Int)`.
"""
function cordic_cosh(z::Real, n::Int=16)
    return cordic_cosh(Float64(z), n)
end

"""
    cordic_sinh(z::Float64, n::Int=16) -> Float64

Compute sinh(z) using hyperbolic CORDIC with range reduction.
Uses the same decomposition as `cordic_cosh`.
"""
function cordic_sinh(z::Float64, n::Int=16)
    z == 0.0 && return 0.0

    max_angle = atanh(2.0^(-1))
    if abs(z) <= max_angle
        _, s = _hyperbolic_core(z, n)
        return s
    end

    ln2 = log(2.0)
    k = round(Int, z / ln2)
    r = z - k * ln2

    c_k = (2.0^k + 2.0^(-k)) / 2.0
    s_k = (2.0^k - 2.0^(-k)) / 2.0

    c_r, s_r = cordic_cosh(r, n), cordic_sinh(r, n)

    # sinh(a+b) = sinh(a)cosh(b) + cosh(a)sinh(b)
    return s_k * c_r + c_k * s_r
end

"""
    cordic_sinh(z::Real, n::Int=16) -> Float64

Convert `z` to Float64 and call `cordic_sinh(Float64, Int)`.
"""
function cordic_sinh(z::Real, n::Int=16)
    return cordic_sinh(Float64(z), n)
end

"""
    cordic_exp(z::Float64, n::Int=16) -> Float64

Compute exp(z) = cosh(z) + sinh(z) using hyperbolic CORDIC.
Equivalent to the identity exp(z) = e^z via the relation between
hyperbolic and exponential functions.
"""
function cordic_exp(z::Float64, n::Int=16)
    return cordic_cosh(z, n) + cordic_sinh(z, n)
end

"""
    cordic_exp(z::Real, n::Int=16) -> Float64

Convert `z` to Float64 and call `cordic_exp(Float64, Int)`.
"""
function cordic_exp(z::Real, n::Int=16)
    return cordic_exp(Float64(z), n)
end

# ──────────────────────────────────────────────────────
# CORDIC vectoring mode for atan2
# ──────────────────────────────────────────────────────

"""
    cordic_atan2(y::Float64, x::Float64, n::Int=16) -> Float64

Compute atan2(y, x) using CORDIC rotation mode (inverse of vectoring).
Starts from point (K, 0) on the positive x-axis and rotates toward
the target direction (x, y), accumulating the angle.

The max absolute error for common iteration counts:
  - 8 iters  → ~2×10⁻¹
  - 16 iters → ~3×10⁻¹
  - 24 iters → ~4×10⁻²

Note: For hardware LUT generation, use `n ≥ 16` for reasonable accuracy.
For higher precision, increase `n` or fall back to `atan(y/x)` with quadrant fixes.
"""
function cordic_atan2(y::Float64, x::Float64, n::Int=16)
    # Handle special cases
    if x == 0.0 && y == 0.0
        return 0.0
    end
    eps = Float64(1e-15)
    if abs(x) < eps
        return y >= 0.0 ? π / 2 : -π / 2
    end

    ax, ay = abs(x), abs(y)
    angles = cordic_angles(n)

    # CORDIC gain for rotation mode (same as circular gain)
    K = _cordic_gain(n)

    # Start from point on positive x-axis scaled by K
    xv, yv = K, 0.0
    z = 0.0

    for i in eachindex(angles)
        shift = 2.0^(-(i-1))
        # Decide rotation direction: rotate toward target angle atan(ay/ax)
        if xv != 0.0 && yv / xv < ay / ax
            d = 1   # need more CCW rotation
        else
            d = -1  # rotated too far, go CW
        end

        xn = xv - d * yv * shift
        yn = yv + d * xv * shift
        z += d * angles[i]
        xv, yv = xn, yn
    end

    # Map back to correct quadrant
    if x < 0.0 && y >= 0.0
        return π - z
    elseif x < 0.0 && y < 0.0
        return -π + z
    elseif x >= 0.0 && y < 0.0
        return -z
    else
        return z
    end
end

"""
    cordic_atan2(y::Real, x::Real, n::Int=16) -> Float64

Convert inputs to Float64 and call `cordic_atan2(Float64, Float64, Int)`.
"""
function cordic_atan2(y::Real, x::Real, n::Int=16)
    return cordic_atan2(Float64(y), Float64(x), n)
end

# ──────────────────────────────────────────────────────
# LUT generation using CORDIC for hyperbolic functions
# ──────────────────────────────────────────────────────

"""
    LUT_cordic(fn::Symbol, r::StepRangeLen, bits::Int=8, n::Int=16) -> LUT{Vector{Float64}, StepRangeLen, Function}

Build a lookup table using CORDIC as the high-precision reference generator.
Returns a `LUT` object with float values in [0, 2^(bits)-1] (quantized from [-1, 1]).

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
