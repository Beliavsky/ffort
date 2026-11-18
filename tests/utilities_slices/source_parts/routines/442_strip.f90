elemental function strip(xx,xchar) result(yy)
! replace trailing characters of xx that equal xchar with a space
character (len=*), intent(in) :: xx
character (len=1), intent(in) :: xchar
character (len=len(xx))       :: yy
integer                       :: i,nlen
yy = xx
nlen = len(xx)
if (nlen < 1) return
do i=nlen,1,-1
   if (yy(i:i) == " ") cycle
   if (yy(i:i) == xchar) then
      yy(i:i) = " "
   else
      return
   end if
end do
end function strip
!
