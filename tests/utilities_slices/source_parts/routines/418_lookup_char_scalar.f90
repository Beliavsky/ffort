function lookup_char_scalar(xx,yy,xkey,ydefault) result(yvalue)
! return the value of yy(:) corresponding to xkey in xx(:), for xx(:), yy(:), xkey of type character
character (len=*), intent(in)           :: xx(:),yy(:) ! (n)
character (len=*), intent(in)           :: xkey
character (len=*), intent(in), optional :: ydefault    ! default value of yvalue when xkey not found in xx
character (len=len(yy))                 :: yvalue
integer                                 :: i,n
n = size(xx)
if (size(yy) /= n) then
   write (*,*) "in lookup, size(xx), size(yy) =",n,size(yy)," must be equal, STOPPING"
   stop
end if
if (present(ydefault)) then
   yvalue = ydefault
else
   yvalue = ""
end if
do i=1,n
   if (xx(i) == xkey) then
      yvalue = yy(i)
      return
   end if
end do
end function lookup_char_scalar
!
