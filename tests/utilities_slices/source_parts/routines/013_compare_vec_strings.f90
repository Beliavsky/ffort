subroutine compare_vec_strings(xx,yy,xname,yname)
! list which elements of xx are not in yy and which elements of yy are not in xx
character (len=*), intent(in) :: xx(:),yy(:)
character (len=*), intent(in), optional :: xname,yname
character (len=100) :: xname_,yname_
logical             :: x_not_in_y(size(xx))
integer             :: i,nx,ny,nx_not_in_y
xname_ = default("x",xname)
yname_ = default("y",yname)
nx = size(xx)
ny = size(yy)
x_not_in_y = [(all(yy/=xx(i)),i=1,size(xx))]
nx_not_in_y = count(x_not_in_y)
if (nx_not_in_y == 0) then
   write (*,*) "all elements of " // trim(xname_) // " are in " // trim(yname_)
else
   write (*,*) nx_not_in_y," elements of " // trim(xname_) // " not in " // trim(yname_) // ":"
   do i=1,nx
      if (x_not_in_y(i)) write (*,*) trim(xx(i))
   end do
   write (*,*)
end if
call compare_vec_strings_(yy,xx,yname,xname)
end subroutine compare_vec_strings
!
