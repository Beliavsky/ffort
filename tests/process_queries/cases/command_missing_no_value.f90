program p
implicit none
integer::n,s
call get_command_argument(1,length=n,status=s)
if(n/=0.or.s<=0) error stop 1
end program
