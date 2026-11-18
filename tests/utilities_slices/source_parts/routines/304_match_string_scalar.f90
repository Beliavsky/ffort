pure function match_string_scalar(ii,ivec) result(ipos)
! return the position of the first element in ivec that
! matches ii, 0 otherwise
character (len=*), intent(in) :: ii,ivec(:)
integer                       :: ipos
integer                       :: j
ipos = 0
do j=1,size(ivec)
   if (ivec(j) == ii) then
   ipos = j
   return
   end if
end do
end function match_string_scalar
!
