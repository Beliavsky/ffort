function capped_sum_abs_rows(xx,cap) result(yy)
! return arrat that is scaled so that the sum of the absolute values of each row does not exceed cap
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp), intent(in) :: cap
real(kind=dp)             :: yy(size(xx,1),size(xx,2))
integer                   :: i
forall (i=1:size(xx,1)) yy(i,:) = capped_sum_abs(xx(i,:),cap)
end function capped_sum_abs_rows
!
