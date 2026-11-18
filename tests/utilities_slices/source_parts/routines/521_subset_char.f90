subroutine subset_char(xfind,xdata,xfound)
! return in xfound the elements of xfind found in xdata
character (len=*), intent(in)               :: xfind(:),xdata(:)
character (len=*), intent(out), allocatable :: xfound(:)
logical                                     :: x_in_y(size(xfind))
x_in_y = xfind .in. xdata
call set_alloc(pack(xfind,x_in_y),xfound)
end subroutine subset_char
!
