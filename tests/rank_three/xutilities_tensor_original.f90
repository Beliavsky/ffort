function tensor(xmat) result(xtens)
! convert a MxN matrix to an MxNx1 tensor
real(kind=dp), intent(in) :: xmat(:,:)
real(kind=dp)             :: xtens(size(xmat,1),size(xmat,2),1)
xtens(:,:,1) = xmat
end function tensor
