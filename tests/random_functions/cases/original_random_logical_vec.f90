module m
implicit none
integer,parameter::dp=kind(0d0)
contains
function random_logical_vec(n,prob) result(tf)
! return a logical vector with n*prob true elements on average
integer, intent(in) :: n
real(kind=dp), intent(in) :: prob
logical             :: tf(n)
real(kind=dp)       :: xx(n)
call random_number(xx)
tf = xx > (1-prob)
end function random_logical_vec
end module
program p
use m
implicit none
logical::x(4096)
x=random_logical_vec(4096,0.25d0)
if(abs(count(x)/4096d0-0.25d0)>0.05d0) error stop 1
x=random_logical_vec(4096,0d0)
if(any(x)) error stop 2
x=random_logical_vec(4096,1d0)
if(.not.all(x)) error stop 3
if(size(random_logical_vec(0,0.5d0))/=0) error stop 4
print *, "PASS"
end program
