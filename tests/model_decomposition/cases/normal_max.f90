program p
implicit none
real::x
real(8)::y
integer::i,j
x=huge(1.);y=huge(1d0);i=128;j=1024
print *,set_exponent(x,i),set_exponent(y,j)
print *,exponent(x),exponent(y),fraction(x),fraction(y)
end program
