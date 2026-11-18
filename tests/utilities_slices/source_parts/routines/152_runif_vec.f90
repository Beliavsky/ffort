function runif_vec(n,xmean) result(xran)
! generate vector of uniform random variates
integer      , intent(in)           :: n
real(kind=dp), intent(in), optional :: xmean
real(kind=dp)                       :: xran(n)
call random_number(xran)
if (present(xmean)) xran = xran + xmean - 0.5_dp
end function runif_vec
!
