program p
implicit none
character(11)::v
integer::n,s
call get_command_argument(status=s,length=n,value=v,number=0)
if(s/=0.or.n/=11.or.v/='program.f90') error stop 1
end program
