module iso_fortran_env
implicit none
integer,parameter::output_unit=77
end module
program p
use,intrinsic:: iso_fortran_env,only:output_unit
implicit none
print '(i0)',output_unit
end program
