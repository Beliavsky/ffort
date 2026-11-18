function join_(cvec,sep,cquote) result(yy)
! join strings
character (len=*), intent(in) :: cvec(:)
character (len=*), intent(in) :: sep
character (len=*), intent(in) :: cquote
character (len=100*size(cvec)) :: yy
integer :: i,n
n = size(cvec)
yy = ""
do i=1,n
   if (i > 1) then
      yy = trim(yy) // sep // cquote // trim(cvec(i)) // cquote
   else
      yy = cquote // trim(cvec(i)) // cquote
   end if
!   if (i < n) yy = trim(yy) + delim
end do
end function join_
!
