program probe
implicit none
integer, allocatable :: a(:)
a=[1,2,3]
print *, allocated(a),size(a),lbound(a,1),ubound(a,1),sum(a)
end program
