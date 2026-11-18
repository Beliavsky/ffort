program p
implicit none
integer :: iu,n
character(18) :: name
iu=17
! GNU_REGISTER_INPUT
write(*,'(a)',advance='no') 'NAME:'
inquire(unit=iu,name=name)
write(*,'(a)') name
read(iu,*) n
write(*,'(i0)') n
end program
