program p
use iso_fortran_env,only:u=>output_unit
implicit none
integer::a
write(u,'(a)',advance='no') 'SAFE'
write(u,'(i0)') a
end program
