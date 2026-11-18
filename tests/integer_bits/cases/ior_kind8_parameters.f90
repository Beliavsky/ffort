program bits_driver
implicit none
integer(8),parameter::x=ior(9223372036854775807_8,53_8)
print *,x,kind(x)
end program
