elemental subroutine bound_value(xx,xmin,xmax)
! bound xx by xmin and xmax
real(kind=dp), intent(in out)           :: xx
real(kind=dp), intent(in)    , optional :: xmin,xmax
if (present(xmin)) xx = max(xx,xmin)
if (present(xmax)) xx = min(xx,xmax)
end subroutine bound_value
!
