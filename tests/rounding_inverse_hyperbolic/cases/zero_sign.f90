program p
implicit none
real(8)::x
x=-0.0d0
print *,sign(1d0,aint(x)),sign(1d0,anint(x)),sign(1d0,asinh(x))
print *,sign(1.0,aint(x,4)),sign(1.0,anint(x,4)),acosh(1d0)
end program
