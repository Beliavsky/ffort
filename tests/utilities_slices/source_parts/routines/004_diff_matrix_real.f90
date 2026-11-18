pure function diff_matrix_real(xx) result(yy)
! return the difference of consecutive elements for each column of yy(:,:)
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp)             :: yy(size(xx,1)-1,size(xx,2))
integer                   :: n
n = size(xx,1)
if (n > 1) yy = xx(2:,:)-xx(:n-1,:)
end function diff_matrix_real
!
