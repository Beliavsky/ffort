program p
use iso_fortran_env,only:output_unit
implicit none
integer::u,i
u=output_unit
do concurrent(i=1:1)
write(u,"(a)")"bad"
end do

end program
