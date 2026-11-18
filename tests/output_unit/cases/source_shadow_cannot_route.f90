module iso_fortran_env
implicit none
integer,parameter::output_unit=77
end module
program p
use iso_fortran_env,only:output_unit
implicit none
write(output_unit,'(a)') 'no'
end program
