module original_utilities
implicit none
integer,parameter::dp=8
interface set_alloc
module procedure set_alloc_real_vec,set_alloc_int_vec
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

subroutine set_optional_alloc_int(xx,xdef,xopt)
! set xx(:) to xopt(:) if present and xdef(:) if not
integer, intent(out), allocatable :: xx(:)
integer, intent(in)               :: xdef(:)
integer, intent(in) , optional    :: xopt(:)
if (present(xopt)) then
   call set_alloc(xopt,xx)
else
   call set_alloc(xdef,xx)
end if
end subroutine set_optional_alloc_int

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

pure recursive subroutine set_alloc_int_vec(ii,jj,jmin,jmax)
! for integer vectors xx(:) and yy(:), allocate yy and set it to xx
! keep only values between jmin and jmax, inclusive, if they are present
integer, intent(in)               :: ii(:)
integer, intent(out), allocatable :: jj(:)
integer, intent(in) , optional    :: jmin,jmax
integer                           :: ni
if (present(jmin) .and. present(jmax)) then
   call set_alloc_int_vec(pack(ii,ii >= jmin .and. ii <= jmax),jj)
else if (present(jmin)) then
   call set_alloc_int_vec(pack(ii,ii >= jmin),jj)
else if (present(jmax)) then
   call set_alloc_int_vec(pack(ii,ii <= jmax),jj)
else
   ni = size(ii)
!   print*,"size(ii)=",size(ii) ! debug
!   print*,"ni=",ni ! debug
   allocate (jj(ni))
   jj = ii
end if
end subroutine set_alloc_int_vec
end module
program main
use original_utilities
implicit none
integer::idef(3),iopt(2)
real(dp)::rdef(3),ropt(2)
integer,allocatable::ii(:),iun(:)
real(dp),allocatable::rr(:),run(:)
idef=2
iopt=7
rdef=2.0_dp
ropt=7.0_dp
call set_optional_alloc_int(ii,idef)
if(size(ii)/=3.or.any(ii/=2)) error stop 1
call set_optional_alloc_int(xopt=iopt,xx=ii,xdef=idef)
if(size(ii)/=2.or.any(ii/=7)) error stop 2
call set_optional_alloc_int(ii,idef,iun)
if(size(ii)/=3.or.any(ii/=2)) error stop 3
call set_optional_alloc_real(rr,rdef)
if(size(rr)/=3.or.any(rr/=2.0_dp)) error stop 4
call set_optional_alloc_real(xopt=ropt,xx=rr,xdef=rdef)
if(size(rr)/=2.or.any(rr/=7.0_dp)) error stop 5
call set_optional_alloc_real(rr,rdef,run)
if(size(rr)/=3.or.any(rr/=2.0_dp)) error stop 6
print *, 'PASS'
end program
