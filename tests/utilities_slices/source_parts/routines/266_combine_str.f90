function combine_str(xx,yy) result(zz)
character (len=*), intent(in) :: xx(:),yy(:)
character (len=100) :: zz(size(xx)+size(yy))
integer :: i,nx,ny
nx = size(xx)
ny = size(yy)
do i=1,nx+ny
   if (i <= nx) then
      zz(i) = trim(xx(i))
   else
      zz(i) = trim(yy(i-nx))
   end if
end do
end function combine_str
!
