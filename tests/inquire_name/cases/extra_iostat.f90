program p
implicit none
integer::iu
character(24)::nm
integer::ios
iu=17
! GNU_REGISTER_INPUT

inquire(unit=iu,name=nm,iostat=ios)

end program
