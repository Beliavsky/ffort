elemental function real_within(x,x1,x2) result(tf)
real(kind=dp), intent(in) :: x,x1,x2
logical                   :: tf
tf = x >= x1 .and. x <= x2
end function real_within
!
