module m
implicit none
integer,parameter::dp=kind(1.0d0)
contains
function vector(xmat) result(xvec)
! convert a matrix to a vector
real(kind=dp), intent(in) :: xmat(:,:)
real(kind=dp)             :: xvec(size(xmat))
xvec = reshape(xmat,(/size(xmat)/))
end function vector
!
end module
program p
use m
implicit none
real(dp)::a(-1:0,2:4),z(0,3)
a=reshape([1.0d0,2.0d0,3.0d0,4.0d0,5.0d0,6.0d0],[2,3])
print *,vector(a)
print *,vector(a(:,4:2:-1))
print *,size(vector(z))
end program
