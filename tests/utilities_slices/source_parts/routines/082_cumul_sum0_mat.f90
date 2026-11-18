function cumul_sum0_mat(xx) result(yy)
! return zero followed by the cumulative sum of xx(:)
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp)             :: yy(size(xx,1)+1,size(xx,2))
integer                   :: ivar
forall (ivar=1:size(xx,2)) yy(:,ivar) = [0.0_dp,cumul_sum_vec(xx(:,ivar))]
end function cumul_sum0_mat
!
