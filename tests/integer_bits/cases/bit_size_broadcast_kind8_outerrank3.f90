program bits_driver
implicit none
integer(8)::a(2),b(2,2,2)
b=1_8
b=b+bit_size(a)
print *,b
end program
