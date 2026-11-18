program p
implicit none
integer::iu
character(:),allocatable::nm
iu=17
! GNU_REGISTER_INPUT
allocate(character(24)::nm)
inquire(unit=iu,name=nm)
write(*,'(a)') '['//nm//']'
end program
