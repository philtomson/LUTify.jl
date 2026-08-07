##########################################################
# LUTify — lookup table generation
# convert functions into lookuptables
# useful for hardware modeling
##########################################################

export LUT, build_lut

# this one would be for passing a function as opposed to a formula:
function build_lut(fn::Function, vars)
    compstr = "[ $(fn)("
    args    = []
    forstr  = " "
    for var in vars
        vname = var[1]
        vrange= var[2]
        push!(args, vname)
        forstr = forstr*"for $vname in $vrange "
    end
    compstr = compstr * join(args, ",") * ") "* forstr * "]"
    @eval $(Meta.parse(compstr))
end

function build_lut(fn::Expr, vars)
    compstr = "[ $(fn)"
    args    = []
    forstr  = " "
    for var in vars
        vname = var[1]
        vrange= var[2]
        push!(args, vname)
        forstr = forstr*"for $vname in $vrange "
    end
    compstr = compstr * forstr * "]"
    @eval $(Meta.parse(compstr))
end

mutable struct LUT{A,R,F}
    f::F
    r::R
    lut::A
end

#TODO: getidx needs to be generalized for multiple inputs
#NOTE: no longer used, but might be later(?)
getidx(val, init_val, step) = round(Int, (val-init_val/step))+1

# single var function constructor
function LUT(fn::Function, r::StepRangeLen)
    lut = [fn(x) for x in r]
    LUT(fn, r, lut)
end

# multi-var function constructor
function LUT(fn::Function, rs::AbstractVector{<:Tuple{Symbol,<:StepRangeLen}})
    lut = build_lut(fn, rs)
    args =      [ r[1] for r in rs ]
    args_syms = [ :(arg) for arg in args]
    LUT(fn, rs, lut)
end

function LUT(fn::Expr, rs::AbstractVector{<:Tuple{Symbol,<:StepRangeLen}})
    lut = build_lut(fn, rs)
    LUT(fn, rs, lut)
end

function range_check_(lut::LUT, vals_dict::Dict)
    for v_r in lut.r
        var    = v_r[1]
        vrange = v_r[2]
        val    = vals_dict[var]
        if !(vrange[1] <= val <= vrange[end])
            error("$var value $val is not between $(vrange[1]) and $(vrange[end])")
        end
    end
end

# get_idx - for integer values & start of range at 0.0 only for now!
function get_idx(lut::LUT, vals_dict)
    range_check_(lut, vals_dict)
    rev_r = reverse(lut.r)
    m = 1
    idx = 1
    function helper(rl)
        if length(rl) == 0
            return
        else
            var     = rl[1][1]
            val     = vals_dict[var]
            r       = rl[1][2]
            rstart  = r[1]
            idx    += ((val-rstart)/step(r)) * m
            m      *= length(r)
            helper(rl[2:end])
        end
    end
    helper(rev_r)
    Int(idx)
end

# access values in LUT: one var only
function (lut::LUT)(x)
    if x < lut.r[1] || x > lut.r[end]
        error("out of range!")
    end
    lut.lut[round(Int, x/lut.r.step.hi) + 1]
end

function (lut::LUT)(x...)
    if length(x) != length(lut.r)
        error("Number of arguments does not match $(length(lut.r))")
    end
    vars_vals = Dict()
    for (index, v_r) in enumerate(IndexStyle(lut.r), lut.r)
        var     = v_r[1]
        vrange  = v_r[2]
        val     = x[index]
        vars_vals[var] = val
    end
    lut.lut[get_idx(lut, vars_vals)]
end
