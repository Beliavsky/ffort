program p
implicit none
print *,set_exponent(huge(1.),128),set_exponent(huge(1d0),1024)
print *,exponent(huge(1.)),exponent(huge(1d0)),fraction(huge(1.)),fraction(huge(1d0))
end program
