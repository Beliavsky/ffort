program p
implicit none
integer::n,s
call get_command_argument(0,length=n,status=s)
if(n/=11.or.s/=0) error stop 1
end program
