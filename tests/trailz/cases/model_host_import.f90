program p
use,intrinsic::iso_fortran_env,only:ks=>integer_kinds,int8
implicit none
call show()
contains
subroutine show()
print *,ks,int8
end subroutine show
end program p
