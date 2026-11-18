module m
implicit none
integer,parameter::dp=kind(0d0)
contains
function random_matrix(nrow,ncol) result(xmat)
integer, intent(in) :: nrow,ncol
real(kind=dp)       :: xmat(nrow,ncol)
call random_number(xmat)
end function random_matrix
end module
program p
use m
implicit none
real(dp)::x(64,64),y(64,64)
x=random_matrix(64,64)
if(any(x<0d0).or.any(x>=1d0)) error stop 1
if(abs(sum(x)/4096d0-0.5d0)>0.05d0) error stop 2
if(abs(sum((x-0.5d0)**2)/4096d0-1d0/12d0)>0.025d0) error stop 3
y=random_matrix(64,64)
if(all(x==y)) error stop 4
if(size(random_matrix(0,3))/=0) error stop 5
print *, "PASS"
end program
