pure function mean(xx) result(xmean)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: xmean
xmean = sum(xx)/max(1,size(xx))
end function mean
!
