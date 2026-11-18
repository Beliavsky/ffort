program p
use,intrinsic::iso_fortran_env,only:ks=>integer_kinds
implicit none
print *,ks(1),ks(2),ks(2:1:-1)
print *,kind(ks(1)),trailz(ks)
end program
