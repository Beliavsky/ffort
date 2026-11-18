function prepend_char(xadd,xx) result(yy)
! set yy equal to [xadd,xx]
character (len=*), intent(in)                  :: xadd(:)
character (len=*), intent(in)                  :: xx(:)
character (len=len(xx(1)))                     :: yy(size(xx)+size(xadd))
integer                                        :: n,nadd
n = size(xx)
nadd = size(xadd)
yy(1:n) = xx
if (nadd > 0) yy(:nadd) = xadd
yy(nadd+1:) = xx
end function prepend_char
!
