program p
implicit none
print *,fraction(0.),exponent(0d0),set_exponent(0d0,99_8)
print *,sign(1.,fraction(-0.)),sign(1d0,set_exponent(-0d0,1000)),exponent(-0.)
end program
