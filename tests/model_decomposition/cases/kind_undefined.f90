program p
implicit none
real(8)::x
integer(8)::i
character::c
print *,kind(fraction(x)),kind(exponent(x)),kind(set_exponent(x,i)),kind(iachar(c,8))
end program
