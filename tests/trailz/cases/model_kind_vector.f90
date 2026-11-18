program p
use,intrinsic::iso_fortran_env,only:integer_kinds
implicit none
print *,integer_kinds
print *,size(integer_kinds),shape(integer_kinds),kind(integer_kinds)
print *,integer_kinds(1),integer_kinds(2),integer_kinds(2:1:-1)
end program p
