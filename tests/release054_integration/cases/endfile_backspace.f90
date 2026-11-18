program p
implicit none
integer :: iu,n,ios
character(15) :: name
iu=17
! GNU_REGISTER_INPUT
read(iu,*) n
read(iu,*) n
read(iu,*,iostat=ios) n
if(ios>=0) error stop 'expected endfile'
inquire(unit=iu,name=name)
backspace(iu)
inquire(unit=iu,name=name)
backspace(iu)
read(iu,*) n
write(*,'(i0,a,a)') n,'|',name
end program
