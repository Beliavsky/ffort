program p
implicit none
integer::n
call get_command_argument(number=0,length=n)
if(n/=11) error stop 1
end program
