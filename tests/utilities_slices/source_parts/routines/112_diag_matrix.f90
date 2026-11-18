pure function diag_matrix(vec) result(mat)
! return a diagonal matrix with elements from vec(:)
real(kind=dp), intent(in) :: vec(:)
real(kind=dp)             :: mat(size(vec),size(vec))
integer                   :: i
mat = 0.0_dp
do i=1,size(vec)
   mat(i,i) = vec(i)
end do
end function diag_matrix
!
