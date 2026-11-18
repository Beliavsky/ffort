program p
use,intrinsic::iso_fortran_env,only:ks=>integer_kinds
implicit none
print *,second()
contains
integer function second()
second=ks(2)
end function
end program
