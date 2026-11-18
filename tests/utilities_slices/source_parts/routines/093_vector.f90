function vector(xmat) result(xvec)
! convert a matrix to a vector
real(kind=dp), intent(in) :: xmat(:,:)
real(kind=dp)             :: xvec(size(xmat))
xvec = reshape(xmat,(/size(xmat)/))
end function vector
!
