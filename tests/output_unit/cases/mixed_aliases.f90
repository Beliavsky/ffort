program p
use iso_fortran_env,only:dp=>real64,output_unit,ik=>int64
implicit none
print '(4i4)',output_unit,dp,ik,kind(output_unit)
end program
