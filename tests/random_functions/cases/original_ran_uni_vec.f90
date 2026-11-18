module m
implicit none
integer,parameter::dp=kind(0d0)
contains
function ran_uni_vec(n) result(xran)
integer, intent(in) :: n
real(kind=dp)       :: xran(n)
call random_number(xran)
end function ran_uni_vec
end module
program p
use m
implicit none
real(dp)::x(4096),y(4096)
x=ran_uni_vec(4096)
if(any(x<0d0).or.any(x>=1d0)) error stop 1
if(abs(sum(x)/4096d0-0.5d0)>0.05d0) error stop 2
if(abs(sum((x-0.5d0)**2)/4096d0-1d0/12d0)>0.025d0) error stop 3
y=ran_uni_vec(4096)
if(all(x==y)) error stop 4
if(size(ran_uni_vec(0))/=0) error stop 5
print *, "PASS"
end program
