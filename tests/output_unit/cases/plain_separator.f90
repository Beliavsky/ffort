program p
use :: iso_fortran_env,only:out=>output_unit
implicit none
print '(2i4)',out,kind(out)
end program
