function pos(xx,xvec) result(ipos)
! return the first position of xvec(:) that matches xx, 0 if no match, -1 if size(xvec) == 0
character (len=*), intent(in) :: xx,xvec(:)
integer                       :: ipos
integer                       :: i,size_xvec
size_xvec = size(xvec)
if (size_xvec == 0) then
   ipos = -1
   return
end if
do i=1,size_xvec
   if (xvec(i) == xx) then
      ipos = i
      return
   end if
end do
ipos = 0
end function pos
!
