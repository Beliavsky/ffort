program bits_driver
implicit none
integer(8)::a(2,3,4)
print *,bit_size(i=a),kind(bit_size(a))
end program
