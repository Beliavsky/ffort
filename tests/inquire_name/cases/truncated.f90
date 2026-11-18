program p
implicit none
integer::iu
character(5)::nm
iu=17
! GNU_REGISTER_INPUT

inquire(unit=iu,name=nm)
write(*,'(a)') '['//nm//']'
end program
