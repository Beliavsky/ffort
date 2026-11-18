program bits_driver
implicit none
integer(8),allocatable::a(:,:)
integer(8)::b(3)
b=bit_size(a)+[1_8,2_8,3_8]
print *,b
end program
