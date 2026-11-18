program p
use,intrinsic::iso_fortran_env,only:ks=>integer_kinds,small=>int8
implicit none
integer,parameter::n=size(ks)
integer::a(n)
a=ks
print *,n,a,small+1
end program p
