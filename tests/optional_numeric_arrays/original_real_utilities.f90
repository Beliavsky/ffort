module original_real_utilities
implicit none
integer,parameter::dp=8
interface set_alloc
module procedure set_alloc_real_vec
end interface
contains
subroutine set_optional_alloc_real(xx,xdef,xopt)
! set xx(:) to xopt(:) if present and xdef(:) if not
real(kind=dp), intent(out), allocatable :: xx(:)
real(kind=dp), intent(in)               :: xdef(:)
real(kind=dp), intent(in) , optional    :: xopt(:)
if (present(xopt)) then
   call set_alloc(xopt,xx)
else
   call set_alloc(xdef,xx)
end if
end subroutine set_optional_alloc_real
subroutine set_alloc_real_vec(xx,yy,nsize)
! for real vectors xx(:) and yy(:), allocate yy and set it to xx
real(kind=dp), intent(in)               :: xx(:)
real(kind=dp), intent(out), allocatable :: yy(:)
integer      , intent(out), optional    :: nsize
integer                                 :: ni
ni = size(xx)
allocate (yy(ni))
yy = xx
if (present(nsize)) nsize = ni
end subroutine set_alloc_real_vec
end module
program main
use original_real_utilities
implicit none
real(dp)::d(3),o(2)
real(dp),allocatable::x(:),a(:)
d=2.0_dp
o=7.0_dp
call set_optional_alloc_real(x,d)
if(size(x)/=3.or.any(x/=2.0_dp)) error stop 1
call set_optional_alloc_real(xopt=o,xx=x,xdef=d)
if(size(x)/=2.or.any(x/=7.0_dp)) error stop 2
call set_optional_alloc_real(x,d,a)
if(size(x)/=3.or.any(x/=2.0_dp)) error stop 3
print *, 'PASS'
end program
