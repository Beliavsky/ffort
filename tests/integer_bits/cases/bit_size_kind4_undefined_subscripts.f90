program bits_driver
implicit none
integer::i,j,s
integer(4)::a(2,2)
print *,bit_size(a(i,j)),bit_size(a(i:j:s,1)),kind(bit_size(a))
end program
