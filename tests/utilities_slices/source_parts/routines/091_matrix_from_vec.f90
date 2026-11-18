function matrix_from_vec(xvec) result(xmat)
! convert a vector of N elements to an Nx1 matrix
real(kind=dp), intent(in) :: xvec(:)
real(kind=dp)             :: xmat(size(xvec),1)
xmat(:,1) = xvec
end function matrix_from_vec
!
