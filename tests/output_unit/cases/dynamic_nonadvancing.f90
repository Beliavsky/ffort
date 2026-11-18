program p
use iso_fortran_env,only:u=>output_unit
implicit none
character(12)::fmt
fmt='(a,t2,a)'
write(unit=u,fmt=fmt,advance='no') 'ABCD','x'
write(*,'(a)') '!'
end program
