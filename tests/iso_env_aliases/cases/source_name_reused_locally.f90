program p
use,intrinsic::iso_fortran_env,only:real32=>real64,real64=>real32
implicit none
real(real32)::x=1.0_real32
real(real64)::y=2.0_real64
print *,real32,real64,kind(x),kind(y)
end program
