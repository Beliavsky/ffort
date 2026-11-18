program probe
implicit none
integer,allocatable :: a(:,:),b(:,:)
allocate(b(-2:-1,4:3))
a=b
print *,allocated(a),size(a),lbound(a,1),ubound(a,1),lbound(a,2),ubound(a,2)
end program
