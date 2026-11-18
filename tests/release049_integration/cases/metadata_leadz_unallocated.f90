program p
use iso_fortran_env, only: output_unit
implicit none
integer(8),allocatable::a(:)
integer::u
u=output_unit
write(u,"(i0,/,a)")kind(leadz(a)),repeat("M",2)
end program
