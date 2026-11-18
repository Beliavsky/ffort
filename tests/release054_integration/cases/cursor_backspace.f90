program p
implicit none
integer :: iu,a,b,c
character(18) :: name
iu=17
! GNU_REGISTER_INPUT
read(iu,*) a
inquire(unit=iu,name=name)
read(iu,*) b
backspace(iu)
inquire(name=name,unit=iu)
read(iu,*) c
write(*,'(i0,1x,i0,1x,i0,1x,a)') a,b,c,trim(name)
end program
