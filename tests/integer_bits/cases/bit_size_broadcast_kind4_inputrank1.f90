program bits_driver
implicit none
integer(4)::a(2),b(3)
b=bit_size(a)+[1_4,2_4,3_4]
print *,b
end program
