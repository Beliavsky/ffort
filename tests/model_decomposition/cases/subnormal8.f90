program p
implicit none
real(8)::x,a,b,c,d
integer(8)::i,j,k
x=tiny(1d0)/2;c=.5d0;d=.75d0;i=-1073_8;j=-1074_8;k=-1075_8
a=set_exponent(c,i);b=set_exponent(d,j)
print *,fraction(x),exponent(x),a,b
print *,fraction(a),exponent(a),set_exponent(c,j),set_exponent(d,k)
end program
