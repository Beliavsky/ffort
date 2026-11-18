program p
use, & ! nature follows
 intrinsic :: iso_fortran_env, only: &
 u => & ! remote follows
 output_unit
implicit none
write(u,'(a)') 'continued'
end program
