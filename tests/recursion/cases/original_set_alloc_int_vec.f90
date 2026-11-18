module original_set_alloc
contains
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
program p
use original_set_alloc
implicit none
integer,allocatable::jj(:)
integer::ii(7)
ii=[-5,-1,0,2,4,8,8]
call set_alloc_int_vec(ii,jj)
print *,size(jj),jj
call set_alloc_int_vec(ii,jj,jmin=0)
print *,size(jj),jj
call set_alloc_int_vec(ii,jj,jmax=2)
print *,size(jj),jj
call set_alloc_int_vec(ii,jj,jmin=0,jmax=4)
print *,size(jj),jj
call set_alloc_int_vec(ii,jj,jmin=9)
print *,allocated(jj),size(jj)
call set_alloc_int_vec(ii(1:0),jj)
print *,allocated(jj),size(jj)
call set_alloc_int_vec(ii(7:1:-2),jj,jmin=-2,jmax=8)
print *,size(jj),jj
end program
