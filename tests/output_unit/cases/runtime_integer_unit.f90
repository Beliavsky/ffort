program p
use iso_fortran_env,only:u=>output_unit
implicit none
integer::v
v=u
write(v,'(a)') 'no'
end program
