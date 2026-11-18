program p
implicit none
integer :: iu
character(8) :: name
! GNU_REGISTER_INPUT
name='original'
write(*,'(a)',advance='no') 'KEEP'
inquire(unit=iu,name=name)
write(*,'(a)') name
end program
