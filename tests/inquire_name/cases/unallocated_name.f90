program p
implicit none
integer::iu
character(:),allocatable::nm
iu=17
! GNU_REGISTER_INPUT

inquire(unit=iu,name=nm)

end program
