program p
implicit none
character(24)::v
integer::n,s
call get_command_argument(0,v,n,s)
if(n/=19.or.s/=0) error stop 1
write(*,'(A)') '['//v//']'
end program
