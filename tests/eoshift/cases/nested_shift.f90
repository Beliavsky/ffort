program p
implicit none
write(*,'(*(i0,1x))')eoshift(eoshift([1,2,3],1,-1),-1,-2)
end program
