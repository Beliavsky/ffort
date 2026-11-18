program p
use,intrinsic::iso_fortran_env,only:small=>int16,word=>int64,ks=>integer_kinds
implicit none
print *,small,word,ks
print *,size(ks),trailz(8_word)
end program p
