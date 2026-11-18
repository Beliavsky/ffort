program p
implicit none
integer,parameter::dp=kind(1.0d0)
real(8)::a(2,3),b(3)
a=reshape([2.0_8,4.0_8,6.0_8,8.0_8,10.0_8,12.0_8],[2,3])
b=[2.0_8,2.0_8,5.0_8]
print *,matrix_by_vector_real(a,b)
contains
function matrix_by_vector_real(xmat,xx) result(ymat)
! divide each column of xmat(:,:) by the corresponding element in xx(:)
real(kind=dp), intent(in) :: xmat(:,:),xx(:)
real(kind=dp)             :: ymat(size(xmat,1),size(xmat,2))
integer                   :: i,n2
n2 = size(xmat,2)
forall (i=1:n2) ymat(:,i) = xmat(:,i)/xx(i)
end function matrix_by_vector_real
end program
