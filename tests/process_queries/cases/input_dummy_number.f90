program p
implicit none
call q(0)
contains
subroutine q(number)
integer,intent(in)::number
integer::n,s
character(20)::v
call get_command_argument(number,v,n,s)
if(v/='program.f90'.or.n/=11.or.s/=0) error stop 1
end subroutine
end program
