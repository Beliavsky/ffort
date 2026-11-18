program p
implicit none
integer::iu
character(24)::nm
integer::inquire
iu=17
! GNU_REGISTER_INPUT

inquire=3
write(*,'(i0)') inquire
end program
