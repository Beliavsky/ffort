program real64_precision
implicit none
real(8)::x(9)
x=[-1.234567890123456d0,-0.987654321098765d0,-0.125d0,-1.0d-200,0.0d0, &
   1.0d-200,0.125d0,0.987654321098765d0,1.234567890123456d0]
print *,sin(x),cos(x),tan(x)
end program
