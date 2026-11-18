program p
implicit none
character(3)::v
integer::n,s
call get_command_argument(0,v,n,s)
if(n/=11.or.s/=-1) error stop 1
write(*,'(A)') '['//v//']'
end program
