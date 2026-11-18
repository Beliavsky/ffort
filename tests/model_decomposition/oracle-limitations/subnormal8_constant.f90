program p
implicit none
real(8)::x,a,b
x=tiny(1d0)/2
a=set_exponent(.5d0,-1073_8);b=set_exponent(.75d0,-1074_8)
print *,fraction(x),exponent(x),a,b
print *,fraction(a),exponent(a),set_exponent(.5d0,-1074_8),set_exponent(.75d0,-1075_8)
end program
