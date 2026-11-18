module snapshots
implicit none
contains
subroutine replace_rows(x,y)
real(8),intent(in)::x(:,:)
real(8),allocatable,intent(out)::y(:,:)
allocate(y(size(x,1),size(x,2)))
y=sign(dim(x,0d0),-1d0)
end subroutine
end module
program main
use snapshots
implicit none
real(8),allocatable::a(:,:)
integer::idx(3)
allocate(a(-1:1,2))
a=reshape([1d0,-2d0,3d0,4d0,5d0,6d0],[3,2])
idx=[1,-1,1]
call replace_rows((a(idx,:)),a)
write(*,'("snapshot:",8(1x,i0))')shape(a),int(a)
a=a([2,1],:)
write(*,'("again:",6(1x,i0))')shape(a),int(a)
write(*,'("model:",3(1x,i0))')kind(tiny(a)),radix(a),count(parity(a<0d0,dim=1))
end program
