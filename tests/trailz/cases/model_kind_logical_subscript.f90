program p
use,intrinsic::iso_fortran_env,only:ks=>integer_kinds
implicit none
print *,ks(.true.)
end program
