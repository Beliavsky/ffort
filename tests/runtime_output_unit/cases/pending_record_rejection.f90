program p
use iso_fortran_env,only:output_unit
integer::u
u=output_unit
write(u,"(a)",advance="no")"KEEP"
u=output_unit+1
write(u,"(a)")"BAD"
end program
