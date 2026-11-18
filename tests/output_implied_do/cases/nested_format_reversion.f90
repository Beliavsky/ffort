program main
implicit none
integer::i,j
write(*,'(2(i0,1x))') ((10*i+j,j=1,2),i=1,3)
end program
