program p
implicit none
integer::iu
character(24)::nm

inquire(unit=iu,name=nm)
write(*,'(a)') '['//nm//']'
end program
