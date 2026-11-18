pure function above_diag(xx) result(yy)
! return in yy(:) the above-diagonal elements of xx(:,:)
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp)             :: yy((size(xx,1)*size(xx,1)-size(xx,1))/2)
integer                   :: i,j,iy,n1,n2
n1 = size(xx,1)
n2 = size(xx,2)
iy = 0
do i=1,n1
   do j=i+1,n2
      iy = iy+1
      yy(iy) = xx(i,j)
      if (iy == size(yy)) return
   end do
end do
end function above_diag
!
