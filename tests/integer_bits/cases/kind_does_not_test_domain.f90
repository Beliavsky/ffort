program bits_driver
implicit none
integer::i,p
print *,kind(btest(i,p)),kind(ior(i,i)),bit_size(not(i))
end program
