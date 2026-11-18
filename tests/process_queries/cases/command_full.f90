program p
implicit none
character(20)::v
integer::n,s
call get_command_argument(0,v,n,s)
if(s/=0.or.n/=11) error stop 1
write(*,'(A)') '['//v//']'
end program
