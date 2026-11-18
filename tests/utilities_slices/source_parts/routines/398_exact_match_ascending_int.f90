subroutine exact_match_ascending_int(ivec,jm,ipos,found,i1)
! return the location ipos>=i1 of the first element of ivec such that ivec(ipos)==jm,
! 0 if jm < ivec(1), and size(ivec)+1 if jm > ivec(size(ivec))
integer, intent(in)           :: ivec(:) ! vector to be searched for match
integer, intent(in)           :: jm      ! value to look for
integer, intent(out)          :: ipos    ! first position at which ivec(ipos) >= jm
logical, intent(out)          :: found   ! .true. if jm found in ivec(:)
integer, intent(in), optional :: i1      ! first position at which to look
integer                       :: i,i1_,n
found = .false.
ipos  = 0
n     = size(ivec)
if (present(i1)) then
   i1_ = max(1,i1)
else
   i1_ = 1
end if
if (n < 1 .or. i1_ > n) return
do i=i1_,n
   if (ivec(i) >= jm) then
      ipos = i
      found = ivec(i) == jm
      return
   end if
end do
end subroutine exact_match_ascending_int
!
