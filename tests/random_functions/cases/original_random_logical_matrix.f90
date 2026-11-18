module m
implicit none
integer,parameter::dp=kind(0d0)
contains
function random_logical_matrix(nrow,ncol,prob) result(tf)
! return a logical matrix with each element having probability prob of being true
integer, intent(in) :: nrow,ncol
real(kind=dp), intent(in) :: prob
logical             :: tf(nrow,ncol)
real(kind=dp)       :: xx(nrow,ncol)
call random_number(xx)
tf = xx > (1-prob)
end function random_logical_matrix
end module
program p
use m
implicit none
logical::x(64,64)
x=random_logical_matrix(64,64,0.25d0)
if(abs(count(x)/4096d0-0.25d0)>0.05d0) error stop 1
x=random_logical_matrix(64,64,0d0)
if(any(x)) error stop 2
x=random_logical_matrix(64,64,1d0)
if(.not.all(x)) error stop 3
if(size(random_logical_matrix(0,3,0.5d0))/=0) error stop 4
print *, "PASS"
end program
