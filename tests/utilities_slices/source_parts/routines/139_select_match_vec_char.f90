subroutine select_match_vec_char(xgood,xx,xuse)
! return in xuse the elements in xx(:) that are in xgood(:)
character (len=*), intent(in)               :: xgood(:),xx(:)
character (len=*), intent(out), allocatable :: xuse(:)
integer                       , allocatable :: iuse(:)
call match_char(xgood,xx,iuse)
call set_alloc(xx(iuse),xuse)
end subroutine select_match_vec_char
!
