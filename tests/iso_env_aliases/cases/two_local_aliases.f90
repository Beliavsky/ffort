program p
use,intrinsic::iso_fortran_env,only:a=>real64,b=>real64
implicit none
real(a)::x=2.0_b
print *,a,b,x,kind(x)
end program
