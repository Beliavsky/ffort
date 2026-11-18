program bits_driver
implicit none
integer(4)::a(2),b(2,2,2)
b=1_4
b=b+bit_size(a)
print *,b
end program
