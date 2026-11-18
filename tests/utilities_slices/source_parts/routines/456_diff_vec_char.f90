function diff_vec_char(xx,yy) result(zz)
! return the elements of xx(:) not in yy(:)
character (len=*)      , intent(in)  :: xx(:),yy(:)
character (len=len(xx)), allocatable :: zz(:)
integer                              :: i
logical                              :: xuse(size(xx))
forall (i=1:size(xx)) xuse(i) = all(yy /= xx(i))
call set_alloc(pack(xx,xuse),zz)
end function diff_vec_char
!
