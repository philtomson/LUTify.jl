##########################################################
# very early beginnings of LUTify.jl
# convert functions into lookuptables
# useful for hardware modeling
##########################################################
mutable struct LuT{A,R,F}
   f::F
   r::R
   lut::A
end

function LuT(fn::Function, r::StepRangeLen)
   lut = [fn(x) for x in r ]
   LuT(fn, r, lut)
end

function (lut::LuT)(x)
   if(x < lut.r[1] ||  x > lut.r[end])
      error("out of range!")
   end
   lut.lut[round(Int, x/lut.r.step.hi) + 1]
end

 #try with identity function
identLut = LuT(x -> x, 0:0.5:10.0)
println(identLut(2.6))

sinlut = LuT(sin, 0.0:(pi/100):2.0*pi)

