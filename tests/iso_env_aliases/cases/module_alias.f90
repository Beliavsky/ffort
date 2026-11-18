module m
use,intrinsic::iso_fortran_env,only:dp=>real64
implicit none
private
integer,parameter,public::wp=dp
public::twice
contains
pure real(wp) function twice(x) result(y)
real(wp),intent(in)::x
y=2.0_wp*x
end function
end module
program p
use m,only:wp,twice
implicit none
print *,wp,twice(1.5_wp)
end program
