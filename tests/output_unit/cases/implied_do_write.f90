program p
use iso_fortran_env,only:u=>output_unit
implicit none
integer::i
write(u,'(*(i0,:,a))') (i,',',i=1,3)
end program
