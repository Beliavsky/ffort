program p
implicit none
integer(8),parameter::x=not(9223372036854775807_8)
print *,x,kind(x)
end program
