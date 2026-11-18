function single_real(xvec) result(tf)
! return .true. at the locations of xvec with values that differ from previous and subsequent elements
real(kind=dp), intent(in) :: xvec(:)
logical             :: tf(size(xvec))
integer             :: i,n
n = size(xvec)
if (n < 1) then
   tf = .true.
   return
end if
do i=1,n
   if (i == 1) then
      tf(i) = xvec(i+1) /= xvec(i)
   else if (i == n) then
      tf(i) = xvec(i-1) /= xvec(i)
   else
      tf(i) = (xvec(i)  /= xvec(i-1)) .and. (xvec(i) /= xvec(i+1))
   end if
end do
end function single_real
!
