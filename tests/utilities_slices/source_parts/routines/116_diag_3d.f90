pure function diag_3d(xx) result(xdiag)
! stack the diagonals of matrices xx(:,:,i), i = 1, num_matrices
real(kind=dp), intent(in) :: xx(:,:,:)
real(kind=dp)             :: xdiag(size(xx,1)*size(xx,3))
integer                   :: i3,n1,n3,j
n1 = size(xx,1)
n3 = size(xx,3)
do i3=1,n3
   j = 1 + (i3-1)*n1
   xdiag(j:j+n1-1) = diag(xx(:,:,i3))
end do
end function diag_3d
!
