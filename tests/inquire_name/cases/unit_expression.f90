program p
implicit none
integer::iu
character(24)::nm
iu=17
! GNU_REGISTER_INPUT

inquire(unit=iu+0,name=nm)

end program
