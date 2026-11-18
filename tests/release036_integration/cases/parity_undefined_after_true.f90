program main
implicit none
logical::m(3)
m(1)=.true.
write(*,'(a)')"before"
write(*,'(2(i0,1x))')7,merge(1,0,parity(m))
end program
