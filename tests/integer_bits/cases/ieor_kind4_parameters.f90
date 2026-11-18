program bits_driver
implicit none
integer(4),parameter::x=ieor(2147483647_4,53_4)
print *,x,kind(x)
end program
