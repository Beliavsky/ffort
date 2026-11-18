subroutine good_pos_int(ivec,ipos,values_include,values_exclude,imin,imax)
! return in ipos the positions in ivec that are not in values_exclude and that are in the range (imin,imax), inclusive
integer, intent(in)               :: ivec(:)
integer, intent(out), allocatable :: ipos(:)
integer, intent(in) , optional    :: values_include(:) ! if present, allowed values in jvec
integer, intent(in) , optional    :: values_exclude(:) ! values to exclude from jvec
integer, intent(in) , optional    :: imin     ! min allowable value in jvec
integer, intent(in) , optional    :: imax     ! max allowable
integer                           :: i,j,jpos(size(ivec)),nj,n
n  = size(ivec)
nj = 0
do i=1,n
   j = ivec(i)
   if (.not. in_range(j,imin,imax)) cycle
   if (present(values_exclude)) then
      if (any(values_exclude == j)) cycle
   end if
   if (present(values_include)) then
      if (all(values_include /= j)) cycle
   end if
   nj = nj + 1
   jpos(nj) = i
end do
allocate (ipos(nj))
ipos = jpos(:nj)
end subroutine good_pos_int
!
