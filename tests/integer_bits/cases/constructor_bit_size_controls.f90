program bits_driver
implicit none
integer::i,j
write(*,"(*(l1))")[(btest(5,j),j=bit_size(i)-1,0,-1)]
end program
