subroutine add_uniform_noise(xx,ran_scale)
! add uniform noise in the range (-ran_scale/2, ran_scale/2) with 1.0_dp the default_value of ran_scale
real(kind=dp), intent(in out) :: xx(:)
real(kind=dp), intent(in), optional :: ran_scale
xx = xx + default(1.0_dp,ran_scale)*(ran_uni(size(xx))-0.5_dp)
end subroutine add_uniform_noise
!
