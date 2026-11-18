function intersection_char(xx,yy) result(zz)
character (len=*)      , intent(in)  :: xx(:),yy(:)
character (len=len(xx)), allocatable :: zz(:)
logical                              :: in_yy(size(xx))
integer                              :: i
do i=1,size(xx)
   in_yy(i) = any(xx(i) == yy)
end do
call set_alloc(pack(xx,in_yy),zz)
end function intersection_char
!
