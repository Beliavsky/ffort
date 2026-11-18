function munge(xx,yy,delim) result(xy)
! create array of strings containing combinations of xx and yy
character (len=*), intent(in) :: xx(:),yy(:),delim
character (len=len(xx)+len(yy)+len(delim)) :: xy(size(xx)*size(yy))
integer :: ix,iy,nx
nx = size(xx)
forall (ix=1:size(xx),iy=1:size(yy)) xy(ix + (iy-1)*nx) = trim(xx(ix)) // delim // trim(yy(iy))
end function munge
!
