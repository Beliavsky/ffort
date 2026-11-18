program p
implicit none
integer(8)::s
s=-2147483649_8
write(*,'(*(i0,1x))')eoshift([1,2,3],s,boundary=-9)
end program
