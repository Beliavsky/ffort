program main
implicit none
real(8),allocatable,dimension(:,:)::a
allocate(a(-1:0,3:5))
a=reshape([1.0_8,2.0_8,3.0_8,4.0_8,5.0_8,6.0_8],[2,3])
print *,size(a),size(a,1),size(a,2),lbound(a,1),ubound(a,2),sum(a),a(0,4)
a(:,4)=a(:,3)+7.0_8
print *,a(-1,4),a(0,4)
deallocate(a)
end program
