module m
implicit none
contains
subroutine copy_rows(x,y)
real(8),intent(in)::x(:,:)
real(8),allocatable,intent(out)::y(:,:)
allocate(y(size(x,1),size(x,2)))
y=x
end subroutine
end module
program p
use m
implicit none
real(8),allocatable::a(:,:)
allocate(a(3,2))
a=reshape([1,2,3,4,5,6],[3,2])
call copy_rows((a([3,1],:)),a)
print *,shape(a),a
end program
