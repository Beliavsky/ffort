program p
implicit none
integer::n,s
n=0
call get_command_argument(n+0,length=n,status=s)
if(n/=11.or.s/=0) error stop 1
end program
