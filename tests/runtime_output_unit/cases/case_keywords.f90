program p
use iso_fortran_env,only:output_unit
implicit none
integer::u
u=output_unit
WRITE(UNIT=u,FMT="(a)",ADVANCE="YES")"PASS"

end program
