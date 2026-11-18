program p
real,allocatable::a(:,:,:)
real(8),allocatable::b(:,:,:)
allocate(a(2,1,2)); allocate(b(1,2,3))
a=1.25
b=0.125d0
print *,sum(a(:,:,1))+sum(a(:,:,2)),sum(b(:,:,1))+sum(b(:,:,2))+sum(b(:,:,3)),size(b,3)
deallocate(a); deallocate(b)
print *,allocated(a),allocated(b)
end program
