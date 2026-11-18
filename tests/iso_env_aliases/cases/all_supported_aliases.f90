program p
use,intrinsic::iso_fortran_env,only:sp=>real32,dp=>real64,i4=>int32,i8=>int64
implicit none
real(sp)::x=1.25_sp
real(dp)::y=2.5_dp
integer(i4)::a=42_i4
integer(i8)::b=12345678901_i8
print *,sp,dp,i4,i8,kind(x),kind(y),kind(a),kind(b),x,y,a,b
end program
