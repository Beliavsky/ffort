program p
use,intrinsic::iso_fortran_env,only:qp=>real128
implicit none
print *,[real(qp)::1]
end program
