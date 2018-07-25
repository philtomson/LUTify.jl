Takes a function with one input and turns it into a lookup
table.  This can be useful for modling harware, for example.  Take the sin function; 
it's difficult to implement in hardware without resorting to something like CORDIC
...or lookup tables. 

Useage:

   LUT(*function*, *stepped range*)

Useage example:

   using LUTify

   sinlut = LUT(sin, 0.0:(pi/100):2.0\*pi)


