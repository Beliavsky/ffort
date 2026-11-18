program p
use,intrinsic::iso_fortran_env,only:int8,int16,int32,int64
implicit none
print *,int8,int16,int32,int64
print *,kind(int8),kind(int16),int8<0,int16<0
end program p
