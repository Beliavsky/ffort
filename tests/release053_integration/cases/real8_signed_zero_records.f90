program p
use iso_fortran_env,only:output_unit
implicit none
real(8)::a(3)
a=[-0.0_8,0.0_8,-2.5_8]
write(output_unit,'(4f6.1)')a([2,1,2,3])
end program
