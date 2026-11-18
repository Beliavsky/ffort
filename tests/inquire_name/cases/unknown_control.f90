program p
implicit none
integer::iu
character(24)::nm
iu=17
! GNU_REGISTER_INPUT

inquire(unit=iu,thing=nm)

end program
