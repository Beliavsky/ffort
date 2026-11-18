pure function pos_keep_char(xx,exclude) result(ipos)
character (len=*), intent(in) :: xx(:),exclude(:)
integer, allocatable :: ipos(:)
integer              :: i,jpos(size(xx)),n
n = size(xx)
forall (i=1:n) jpos(i) = merge(0,i,(any(exclude == xx(i))))
call set_alloc(pack(jpos,jpos > 0),ipos)
end function pos_keep_char
!
