module m
implicit none
integer,parameter::dp=kind(0d0)
contains
function random_logical_3d(n1,n2,n3,prob) result(tf)
! return a logical matrix with each element having probability prob of being true
integer      , intent(in) :: n1,n2,n3
real(kind=dp), intent(in) :: prob
logical                   :: tf(n1,n2,n3)
real(kind=dp)             :: xx(n1,n2,n3)
call random_number(xx)
tf = xx > (1-prob)
end function random_logical_3d
end module
program p
use m
implicit none
logical::x(16,16,16)
integer::j,nt
x=random_logical_3d(16,16,16,0.25d0)
nt=0
do j=1,16
nt=nt+count(x(:,:,j))
end do
if(abs(nt/4096d0-0.25d0)>0.05d0) error stop 1
x=random_logical_3d(16,16,16,0d0)
do j=1,16
if(any(x(:,:,j))) error stop 2
end do
x=random_logical_3d(16,16,16,1d0)
do j=1,16
if(.not.all(x(:,:,j))) error stop 3
end do
if(size(random_logical_3d(2,0,3,0.5d0))/=0) error stop 4
print *, "PASS"
end program
