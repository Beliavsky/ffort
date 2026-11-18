program bits_driver
implicit none
integer(4)::a(0,2,3)
print *,bit_size(a),bit_size([integer(4)::])
end program
