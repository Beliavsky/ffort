program p
use iso_fortran_env, only: output_unit
implicit none
integer :: iu
character(8) :: name
! GNU_REGISTER_INPUT
iu=output_unit
name='original'
write(*,'(a)',advance='no') 'KEEP'
inquire(unit=iu,name=name)
write(*,'(a)') name
end program
