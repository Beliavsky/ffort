module tensor_fixture
implicit none
integer,parameter :: dp=kind(1.0d0)
contains
function tensor(xmat) result(xtens)
! convert a MxN matrix to an MxNx1 tensor
real(kind=dp), intent(in) :: xmat(:,:)
real(kind=dp)             :: xtens(size(xmat,1),size(xmat,2),1)
xtens(:,:,1) = xmat
end function tensor
end module tensor_fixture
program synthetic_tensor_driver
use tensor_fixture
implicit none
real(kind=dp) :: aa(2,3),bb(2,3,1)
integer :: i,j
do j=1,3
do i=1,2
aa(i,j)=10*j+i
end do
end do
bb=tensor(aa)
print *,bb,size(bb,1),size(bb,2),size(bb,3)
end program synthetic_tensor_driver
