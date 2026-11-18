program p
implicit none
integer,parameter::dp=kind(1.0d0)

print *,sign_changes_real([1.0_8,-1.0_8,0.0_8,-2.0_8,3.0_8])
contains
function sign_changes_real(xx) result(tf)
real(kind=dp), intent(in) :: xx(:)
logical                   :: tf(size(xx))
integer                   :: i,n
n = size(xx)
if (n < 1) return
tf(1) = .false.
forall (i=2:n) tf(i) = (xx(i) > 0.0_dp .and. xx(i-1) < 0.0_dp) .or. (xx(i) < 0.0_dp .and. xx(i-1) > 0.0_dp)
end function sign_changes_real
end program
