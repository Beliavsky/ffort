program p
implicit none
integer::iu
character(24)::nm(2)
iu=17
! GNU_REGISTER_INPUT

inquire(unit=iu,name=nm(1))

end program
