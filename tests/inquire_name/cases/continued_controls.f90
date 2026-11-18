program p
implicit none
integer::iu
character(24)::nm
iu=17
! GNU_REGISTER_INPUT

inquire( unit=iu, &
 & name=nm)
write(*,'(a)') '['//nm//']'
end program
