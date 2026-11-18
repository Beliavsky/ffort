program p
integer,allocatable::a(:,:,:),b(:,:,:)
allocate(a(-2:-1,4:5,9:8))
print *,allocated(a),size(a),size(a,1),size(a,2),size(a,3)
print *,lbound(a,1),lbound(a,2),lbound(a,3),ubound(a,3)
b=a
print *,allocated(b),size(b),size(b,1),size(b,2),size(b,3)
deallocate(a); deallocate(b)
print *,allocated(a),allocated(b)
end program
