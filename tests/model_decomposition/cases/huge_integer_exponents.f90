program p
implicit none
integer(8)::i
i=9223372036854775807_8
print *,set_exponent(-0d0,i)
i=-i-1_8
print *,set_exponent(1d0,i),sign(1d0,set_exponent(-1d0,i))
end program
