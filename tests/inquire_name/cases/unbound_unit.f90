program p
implicit none
integer::iu
character(24)::nm
iu=17
! GNU_REGISTER_INPUT
iu=19
inquire(unit=iu,name=nm)

end program
