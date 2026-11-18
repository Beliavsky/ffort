program p
implicit none
character(20)::v
integer::n,s
call get_command_argument(0,v,n,s)
if(v/='program.f90'.or.n/=11.or.s/=0) error stop 1
call get_command_argument(3,v,n,s)
if(v/=' '.or.n/=0.or.s<=0) error stop 2
call get_command_argument(0,v,n,s)
if(v/='program.f90'.or.n/=11.or.s/=0) error stop 3
end program
