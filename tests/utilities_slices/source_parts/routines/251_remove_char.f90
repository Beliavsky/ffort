elemental function remove_char(xx,xrem) result(yy)
! remove instances of character xrem from xx
character (len=*), intent(in) :: xx
character (len=*), intent(in), optional :: xrem
character (len=len(xx))       :: yy
integer                       :: i,j
if (.not. present(xrem)) then
   yy = xx
   return
end if
j  = 1
yy = ""
do i=1,len(xx)
   if (index(xrem,xx(i:i)) /= 0) cycle
   yy(j:j) = xx(i:i)
   j = j+1
end do
end function remove_char
!
