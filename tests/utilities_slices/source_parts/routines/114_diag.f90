pure function diag(xx) result(xdiag)
! extract the diagonal of a matrix
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp)             :: xdiag(size(xx,1))
integer                   :: i,n1,n2
n1 = size(xx,1)
n2 = size(xx,2)
forall (i=1:min(n1,n2)) xdiag(i) = xx(i,i)
end function diag
!
