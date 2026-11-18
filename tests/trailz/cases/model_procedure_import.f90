program p
implicit none
call show()
contains
subroutine show()
use,intrinsic::iso_fortran_env,only:ks=>integer_kinds,k=>int16
print *,ks,k
end subroutine show
end program p
