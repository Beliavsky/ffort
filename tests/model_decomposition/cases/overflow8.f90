program p
implicit none
integer(8)::i
i=9223372036854775807_8
print *,set_exponent(1d0,i)
end program
