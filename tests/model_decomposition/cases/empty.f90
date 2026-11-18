program p
implicit none
real::x(0)
integer::i(0)
character::c(0)
print *,size(fraction(x)),size(exponent(x)),size(set_exponent(1.,i)),size(iachar(c,8))
end program
