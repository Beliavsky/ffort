subroutine good_pos_char(ivec,ipos,values_include,values_exclude)
! return in ipos the positions in ivec that are not in values_exclude inclusive
character(len=*), intent(in)               :: ivec(:)
integer         , intent(out), allocatable :: ipos(:)
character(len=*), intent(in) , optional    :: values_include(:) ! if present, allowed values in jvec
character(len=*), intent(in) , optional    :: values_exclude(:) ! values to exclude from jvec
integer                           :: i,jpos(size(ivec)),nj,n
n  = size(ivec)
nj = 0
do i=1,n
   if (present(values_exclude)) then
      if (any(values_exclude == ivec(i))) cycle
   end if
   if (present(values_include)) then
      if (all(values_include /= ivec(i))) cycle
   end if
   nj = nj + 1
   jpos(nj) = i
end do
allocate (ipos(nj))
ipos = jpos(:nj)
end subroutine good_pos_char
!
