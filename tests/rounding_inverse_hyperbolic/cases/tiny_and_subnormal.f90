program p
implicit none
real(4)::a
real(8)::b
a=nearest(0.0,1.0)
b=nearest(0d0,1d0)
print *,asinh(a),asinh(-a),asinh(b),asinh(-b)
print *,aint(a),anint(a),aint(b),anint(b)
end program
