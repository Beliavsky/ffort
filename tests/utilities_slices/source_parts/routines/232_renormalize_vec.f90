subroutine renormalize_vec(xx)
real(kind=dp), intent(in out) :: xx(:)
real(kind=dp)                 :: xsum
if (size(xx) < 1) return
xsum = sum(xx)
if (abs(xsum) > 0.0_dp) xx = xx/xsum
end subroutine renormalize_vec
!
