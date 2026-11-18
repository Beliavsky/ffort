subroutine unique_values_int(ivec,uniq,i1,freq)
! return in uniq(:) the unique integer values in ivec
! and in i1(:) the first positions where they are found
integer          , intent(in)                         :: ivec(:) ! (n)
integer          , intent(out),           allocatable :: uniq(:)
integer          , intent(out), optional, allocatable :: i1(:)
integer          , intent(out), optional, allocatable :: freq(:)
integer                                               :: i,ipos(size(ivec)),nuniq ! (n) positions of unique integers in ivec
call unique(ivec,ipos,nuniq) ! output: ipos(:), nuniq
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
end subroutine unique_values_int
!
