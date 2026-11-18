module m
implicit none
interface choose
module procedure ints,reals
end interface
contains
subroutine ints(tag,x)
integer,intent(in)::tag
integer,optional,intent(in)::x(:)
if(tag/=1) error stop 1
if(present(x)) then
if(sum(x)/=6) error stop 2
end if
end subroutine
subroutine reals(tag,x)
real(8),intent(in)::tag
real(8),optional,intent(in)::x(:,:)
if(tag/=2.0_8) error stop 3
if(present(x)) then
if(sum(x)/=8.0_8) error stop 4
end if
end subroutine
end module
program main
use m
implicit none
integer::i(3)
real(8)::r(2,2)
i=2
r=2.0_8
call choose(x=i,tag=1)
call choose(tag=1)
call choose(x=r,tag=2.0_8)
call choose(tag=2.0_8)
print *, 'PASS'
end program
