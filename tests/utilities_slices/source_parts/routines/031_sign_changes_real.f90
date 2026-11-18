function sign_changes_real(xx) result(tf)
real(kind=dp), intent(in) :: xx(:)
logical                   :: tf(size(xx))
integer                   :: i,n
n = size(xx)
if (n < 1) return
tf(1) = .false.
forall (i=2:n) tf(i) = (xx(i) > 0.0_dp .and. xx(i-1) < 0.0_dp) .or. (xx(i) < 0.0_dp .and. xx(i-1) > 0.0_dp)
end function sign_changes_real
!
