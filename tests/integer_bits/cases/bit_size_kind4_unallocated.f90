program bits_driver
implicit none
integer(4),allocatable::a(:,:)
print *,bit_size(a),kind(bit_size(a))
end program
