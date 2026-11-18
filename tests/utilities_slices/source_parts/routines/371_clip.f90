elemental function clip(xx,xmin,xmax) result(yy)
real(kind=dp), intent(in) :: xx,xmin,xmax
real(kind=dp)             :: yy
yy = min(xmax,max(xmin,xx))
end function clip
!
