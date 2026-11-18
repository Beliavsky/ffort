program p
use iso_fortran_env,only:output_unit
implicit none
integer::u
do u=output_unit,output_unit
write(u,"(a)")"PASS"
end do

end program
