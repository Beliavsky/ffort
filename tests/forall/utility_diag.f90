program p
implicit none
integer,parameter::dp=kind(1.0d0)
real(8)::a(2,3)
a=reshape([1.0_8,2.0_8,3.0_8,4.0_8,5.0_8,6.0_8],[2,3])
print *,diag(a)
contains
pure function diag(xx) result(xdiag)
! extract the diagonal of a matrix
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp)             :: xdiag(size(xx,1))
integer                   :: i,n1,n2
n1 = size(xx,1)
n2 = size(xx,2)
forall (i=1:min(n1,n2)) xdiag(i) = xx(i,i)
end function diag
end program
