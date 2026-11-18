program probe
implicit none
real(8), allocatable :: a(:)
allocate(a(-2:0))
a=2
print *,lbound(a,1),ubound(a,1),a
end program
