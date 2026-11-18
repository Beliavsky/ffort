program probe
implicit none
integer, allocatable :: a(:)
allocate(a(-2:0))
a=[1,2,3]
print *,lbound(a,1),ubound(a,1),a
a=[4,5]
print *,lbound(a,1),ubound(a,1),a
end program
