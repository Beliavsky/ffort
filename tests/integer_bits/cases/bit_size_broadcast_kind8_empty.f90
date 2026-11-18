program bits_driver
implicit none
integer(8),allocatable::a(:,:)
integer(8)::b(0,2,3)
b=b+bit_size(a)
print *,size(b),kind(bit_size(a))
end program
