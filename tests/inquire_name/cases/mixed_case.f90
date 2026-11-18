program p
implicit none
integer::iu
character(24)::nm
iu=17
! GNU_REGISTER_INPUT

InQuIrE ( UnIt = iu, NaMe = nm )
write(*,'(a)') '['//nm//']'
end program
