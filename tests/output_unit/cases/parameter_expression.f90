program p
use iso_fortran_env,only:output_unit
implicit none
integer,parameter::a=output_unit+1
print '(i0)',a
end program
