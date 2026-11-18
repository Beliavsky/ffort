function num_obs_bins(xx,thresh) result(nn)
! count the number of observations in xx(:) in regions defined by ascending thresholds thresh(:)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp), intent(in) :: thresh(:)
integer                   :: nn(size(thresh)+1),i,j,k
nn = 0
do i=1,size(xx)
   j = size(nn)
   do k=1,size(thresh)
      if (xx(i) <= thresh(k)) then
         j = k
         exit
      end if
   end do
   nn(j) = nn(j) + 1
end do
end function num_obs_bins
!
