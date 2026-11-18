program p
implicit none
integer::iu
character(24),parameter::nm='unchanged'
iu=17
! GNU_REGISTER_INPUT

inquire(unit=iu,name=nm)

end program
