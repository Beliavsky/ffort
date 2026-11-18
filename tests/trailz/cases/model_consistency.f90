program p
use,intrinsic::iso_fortran_env,only:integer_kinds,int32,int64
implicit none
print *,all(integer_kinds==[int32,int64]),bit_size(0_int32),bit_size(0_int64)
print *,trailz(0_int32),trailz(0_int64)
end program p
