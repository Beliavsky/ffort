program main
implicit none
character(:),allocatable::s
integer::v,ios
s='1'//new_line('x')//'2'
read(s,*,iostat=ios) v
if(ios<=0) error stop 1
write(*,'(a)') 'ok'
end program
