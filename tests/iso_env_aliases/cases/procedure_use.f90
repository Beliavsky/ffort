program p
implicit none
call show()
contains
subroutine show()
use,intrinsic::iso_fortran_env,only:dp=>real64,i8=>int64
implicit none
real(dp)::x
integer(i8)::n
x=2.5_dp
n=42_i8
print *,dp,i8,kind(x),kind(n),x,n
end subroutine
end program
