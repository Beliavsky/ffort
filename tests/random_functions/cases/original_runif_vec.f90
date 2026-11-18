module m
implicit none
integer,parameter::dp=kind(0d0)
contains
function runif_vec(n,xmean) result(xran)
! generate vector of uniform random variates
integer      , intent(in)           :: n
real(kind=dp), intent(in), optional :: xmean
real(kind=dp)                       :: xran(n)
call random_number(xran)
if (present(xmean)) xran = xran + xmean - 0.5_dp
end function runif_vec
end module
program p
use m
implicit none
real(dp)::x(4096),y(4096)
x=runif_vec(4096)
if(any(x<0d0).or.any(x>=1d0)) error stop 1
if(abs(sum(x)/4096d0-0.5d0)>0.05d0) error stop 2
if(abs(sum((x-0.5d0)**2)/4096d0-1d0/12d0)>0.025d0) error stop 3
y=runif_vec(4096)
if(all(x==y)) error stop 4
if(size(runif_vec(0))/=0) error stop 5
x=runif_vec(4096,3d0)
if(any(x<2.5d0).or.any(x>=3.5d0)) error stop 6
if(abs(sum(x)/4096d0-3d0)>0.05d0) error stop 7
print *, "PASS"
end program
