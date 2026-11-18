function single_integer(ivec) result(tf)
! return .true. at the locations of ivec with values that differ from previous and subsequent elements
integer, intent(in) :: ivec(:)
logical             :: tf(size(ivec))
integer             :: i,n
n = size(ivec)
if (n < 1) then
   tf = .true.
   return
end if
  do i=1,n
   if (i == 1) then
      tf(i) = ivec(i+1) /= ivec(i)
   else if (i == n) then
      tf(i) = ivec(i-1) /= ivec(i)
   else
      tf(i) = (ivec(i)  /= ivec(i-1)) .and. (ivec(i) /= ivec(i+1))
   end if
end do
end function single_integer
!
