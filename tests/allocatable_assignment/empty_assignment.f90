program probe
implicit none
integer, allocatable :: a(:),b(:)
allocate(b(-3:-4))
a=b
print *,allocated(a),size(a),lbound(a,1),ubound(a,1)
end program
