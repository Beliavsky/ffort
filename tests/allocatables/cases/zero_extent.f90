program main
implicit none
integer,allocatable::a(:),b(:,:)
allocate(a(-2:-3))
allocate(b(-1:-2,3:6))
a=5
b=4
print *,allocated(a),size(a),lbound(a,1),ubound(a,1),allocated(b),size(b),size(b,2),lbound(b,2),ubound(b,2)
deallocate(a)
deallocate(b)
end program
