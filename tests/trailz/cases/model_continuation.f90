program p
use, intrinsic :: iso_fortran_env, only : &
 & tinykind => int8, & ! comment
 & ks => integer_kinds
implicit none
print *,tinykind,ks
end program p
