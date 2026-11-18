program p
use,intrinsic::iso_fortran_env,only:stdout=>output_unit
implicit none
write(stdout,'(2i4)') stdout,kind(stdout)
end program
