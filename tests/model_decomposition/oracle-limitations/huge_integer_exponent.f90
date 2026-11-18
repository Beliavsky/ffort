program probe
use, intrinsic :: iso_fortran_env, only:int64
implicit none
integer(int64)::i
real(8)::x(2)
x=[1d0,-1d0]
i=-huge(0_int64)
print *, 'runtime negative huge',set_exponent(x,i)
print *, 'runtime zero count',count(set_exponent(x,i)==0d0)
print *, 'folded negative huge',set_exponent([1d0,-1d0],-9223372036854775807_int64)
i=i-1_int64
print *, 'runtime minimum',set_exponent(x,i)
end program
