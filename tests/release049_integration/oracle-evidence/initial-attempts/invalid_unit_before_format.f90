program p
use iso_fortran_env, only: output_unit
implicit none
integer::u
character(12)::fmt
write(*,"(a)",advance="no")"SAFE"
u=99
fmt="(bad)"
write(u,fmt)leadz(1)
end program
