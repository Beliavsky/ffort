function normalize(xx) result(yy)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: yy(size(xx))
yy = xx/max(sum(abs(xx)),tiny_real)
end function normalize
!
