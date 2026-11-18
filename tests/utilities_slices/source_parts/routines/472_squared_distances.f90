function squared_distances(xx) result(xdist)
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp)             :: xdist(size(xx,2),size(xx,2))
integer                   :: i,j,ncol
ncol = size(xx,2)
do i=1,ncol
   do j=1,i-1
      xdist(i,j) = sum((xx(:,i)-xx(:,j))**2)
   end do
   xdist(i,i) = 0.0_dp
end do
do i=1,ncol
   do j=i+1,ncol
      xdist(i,j) = xdist(j,i)
   end do
end do
end function squared_distances
!
