program main
implicit none
logical::x(1,1,1)
x=.true.
write(*,'(i0)')merge(1,0,parity(x))
end program
