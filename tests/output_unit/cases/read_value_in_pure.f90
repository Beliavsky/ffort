program p
use iso_fortran_env,only:u=>output_unit
implicit none
print '(i0)',get()
contains
pure integer function get() result(v)
v=u
end function
end program
