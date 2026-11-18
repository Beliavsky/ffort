program p
implicit none
real::x,a,b,c,d
integer::i,j,k
x=tiny(1.)/2;c=.5;d=.75;i=-148;j=-149;k=-150
a=set_exponent(c,i);b=set_exponent(d,j)
print *,fraction(x),exponent(x),a,b
print *,fraction(a),exponent(a),set_exponent(c,j),set_exponent(d,k)
print *,sign(1.,set_exponent(-d,k))
end program
