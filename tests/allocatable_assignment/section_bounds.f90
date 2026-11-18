program probe
implicit none
integer, allocatable :: a(:),b(:)
allocate(b(-3:-1))
b=[1,2,3]
a=b(-2:-1)
print *,lbound(a,1),ubound(a,1),a
end program
