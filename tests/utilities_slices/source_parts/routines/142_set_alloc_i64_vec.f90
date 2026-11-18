pure recursive subroutine set_alloc_i64_vec(ii,jj,jmin,jmax)
! for integer vectors xx(:) and yy(:), allocate yy and set it to xx
integer(kind=i64), intent(in)               :: ii(:)
integer(kind=i64), intent(out), allocatable :: jj(:)
integer(kind=i64), intent(in) , optional    :: jmin,jmax
integer(kind=i64)                           :: ni
if (present(jmin) .and. present(jmax)) then
   call set_alloc(pack(ii,ii >= jmin .and. ii <= jmax),jj)
else if (present(jmin)) then
   call set_alloc(pack(ii,ii >= jmin),jj)
else if (present(jmax)) then
   call set_alloc(pack(ii,ii <= jmax),jj)
else
   ni = size(ii)
   allocate (jj(ni))
   jj = ii
end if
end subroutine set_alloc_i64_vec
!
