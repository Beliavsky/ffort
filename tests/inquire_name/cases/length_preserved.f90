program p
implicit none
integer::iu
character(:),allocatable::nm
iu=17
! GNU_REGISTER_INPUT
allocate(character(5)::nm)
inquire(unit=iu,name=nm)
write(*,'(a,i0,a)') '['//nm//'] ',len(nm),' chars'
end program
