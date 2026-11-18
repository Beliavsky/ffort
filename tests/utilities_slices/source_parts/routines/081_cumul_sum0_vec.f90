pure function cumul_sum0_vec(xx) result(yy)
! return zero followed by the cumulative sum of xx(:)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: yy(size(xx)+1)
yy = [0.0_dp,cumul_sum_vec(xx)]
end function cumul_sum0_vec
!
