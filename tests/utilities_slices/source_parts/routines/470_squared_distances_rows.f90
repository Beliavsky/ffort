function squared_distances_rows(xx) result(xdist)
! compute Euclidean squared distances between rows
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp)             :: xdist(size(xx,1),size(xx,1))
integer                   :: i,j,nrows
nrows = size(xx,1)
do i=1,nrows
   do j=1,i-1
      xdist(i,j) = sum((xx(i,:)-xx(j,:))**2)
   end do
   xdist(i,i) = 0.0_dp
end do
do i=1,nrows
   do j=i+1,nrows
      xdist(i,j) = xdist(j,i)
   end do
end do
end function squared_distances_rows
!
