##########################################################
# very early beginnings of LUTify.jl
# convert functions into lookuptables
# useful for hardware modeling
##########################################################
mutable struct LUT{A,R,F}
   f::F
   r::R
   lut::A
end

 ## The beginning of multi-var support:
 #this one would be for passing a function as opposed to a formula:
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
   @show compstr
   @eval $(Meta.parse(compstr))
end

#TODO: getidx needs to be generalized for multiple inputs
getidx(val, init_val, step) = round(Int, (val-init_val/step))+1

 #function getid(lut::LUT

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
    @show compstr
    @eval $(Meta.parse(compstr))
 end

function LUT(fn::Function, r::StepRangeLen)
   lut = [fn(x) for x in r ]
   LUT(fn, r, lut)
end

function LUT(fn::Expr, rs::Array{Tuple{Symbol,StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}}},1})
   lut = build_lut(fn, rs)
   LUT(fn, rs, lut)
end

function (lut::LUT)(x)
   if(x < lut.r[1] ||  x > lut.r[end])
      error("out of range!")
   end
   lut.lut[round(Int, x/lut.r.step.hi) + 1]
end



 #try with identity function
identLut = LUT(x -> x, 0:0.5:10.0)
println(identLut(2.6))

sinlut = LUT(sin, 0.0:(pi/100):2.0*pi)

exprlut = build_lut(:(2*x*y^2), [(:x, 0.0:0.1:10.0), (:y, 0.0:0.1:10.0)])

fn(x,y)   = 2x*y^2
fnlut   = build_lut(fn, [(:x, 0.0:0.1:10.0), (:y, 0.0:0.1:10.0)])

exprlut2 = LUT(:(x+y+z), [(:x, 0.0:0.1:10.0), (:y, 0.0:0.1:10.0), (:z, 0.0:10.0)])

function range_check_(lut::LUT, vals_dict)
   for v_r in lut.r
      var    = v_r[1]
      vrange = v_r[2] 
      val  = vals_dict[var]
      if( !(vrange[1] <= val <= vrange[end]) )
         error("$var value $val is not between $(vrange[1]) and $(vrange[end])")
      end
   end
end

#get_idx - for integer values & start of range at 0.0 only for now!
function get_idx(lut::LUT, vals_dict)
   range_check_(lut, vals_dict)
   rev_r = reverse(lut.r)
   m = 1
   idx = 1
   function helper(rl)
      if(length(rl) == 0)
         return
      else   
         var = rl[1][1]
         val = vals_dict[var]
         r = rl[1][2]
         rstart = r[1]
         idx += ((val-rstart)/step(r)) * m
         m   *= length(r)
         helper(rl[2:end])
      end
   end
   helper(rev_r)
   @show "return idx is: $idx"
   Int(idx)
end

@show exprlut2.lut[get_idx(exprlut2, Dict(:x=>4, :y=>3, :z=>1))]

exprlut3 = LUT(:(x+y+z), [(:x, 2.0:0.1:8.0), (:y, 1.0:0.1:10.0), (:z, 0.0:10.0)])

@show exprlut3.lut[get_idx(exprlut3, Dict(:x=>4.2, :y=>3.5, :z=>10.0))]

