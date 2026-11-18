program p
implicit none
real(4)::a
real(8)::b
a=huge(1.0)
b=huge(1d0)
print *,aint(a),anint(a),aint(b),anint(b)
print *,asinh(a),asinh(-a),acosh(a),asinh(b),asinh(-b),acosh(b)
end program
