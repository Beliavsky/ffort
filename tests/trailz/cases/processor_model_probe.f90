program p
use,intrinsic::iso_fortran_env,only:int8,int16,int32,int64,integer_kinds
implicit none
print *,int8,int16,int32,int64
print *,integer_kinds
print *,size(integer_kinds),kind(integer_kinds)
end program p
