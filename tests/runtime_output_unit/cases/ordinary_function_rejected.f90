program p
use iso_fortran_env,only:output_unit
implicit none
integer::i
i=q(output_unit)
contains
integer function q(u)
integer,intent(in)::u
write(u,"(a)")"bad"
q=0
end function
end program
