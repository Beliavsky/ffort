program p
implicit none
integer::iu
character(24)::nm
iu=17
! GNU_REGISTER_INPUT

inquire(name=nm,unit=iu)
write(*,'(a)') '['//nm//']'
end program
