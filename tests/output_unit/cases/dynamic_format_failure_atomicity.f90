program p
use iso_fortran_env,only:u=>output_unit
implicit none
character(3)::fmt
fmt='(q)'
write(u,'(a)',advance='no') 'SAFE'
write(u,fmt) 7
end program
