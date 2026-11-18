program main
implicit none
character(2),allocatable::x(:)
allocate(x(0:2))
x=['aa','bb','cc']
x=x([2,0,2,1])
print '(i0,1x,i0,1x,4a2)',lbound(x,1),ubound(x,1),x
end program
