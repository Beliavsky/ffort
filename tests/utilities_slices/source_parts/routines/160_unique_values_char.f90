subroutine unique_values_char(ivec,uniq,i1,freq,igroup)
! return in uniq(:) the unique character values in ivec,
! in i1(:) the first positions where they are found, and
! in freq(:) their frequencies
character (len=*), intent(in)                         :: ivec(:) ! (n)
character (len=*), intent(out),           allocatable :: uniq(:)
integer          , intent(out), optional, allocatable :: i1(:)
integer          , intent(out), optional, allocatable :: freq(:)
integer          , intent(out), optional              :: igroup(:)
integer                                               :: i,ipos(size(ivec)),nuniq ! (n) positions of unique integers in ivec
call unique_char(ivec,ipos,nuniq)
if (nuniq > 0) then
   call set_alloc(ivec(ipos(:nuniq)),uniq)
else
   allocate (uniq(0))
end if
if (present(i1)) then
   if (nuniq > 0) then
      call set_alloc(ipos(:nuniq),i1)
   else
      allocate (i1(0))
   end if
end if
if (present(freq)) then
   allocate (freq(nuniq))
   do i=1,nuniq
      freq(i) = count(ivec==uniq(i))
   end do
end if
if (present(igroup)) then
   if (size(igroup) /= size(ivec)) then
      igroup = -1
      return
   else
      igroup = match_string(ivec,uniq)
   end if
end if
end subroutine unique_values_char
!
