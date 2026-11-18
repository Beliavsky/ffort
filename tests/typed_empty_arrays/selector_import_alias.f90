program p
use,intrinsic::iso_fortran_env,only:i8=>int64,r8=>real64
implicit none
integer(i8)::a(0)
real(r8)::b(0)
a=[integer(i8)::]
b=[real(r8)::]
if(kind([integer(i8)::])/=8.or.kind([real(r8)::])/=8) error stop 1
print *, 'PASS' 
end program
