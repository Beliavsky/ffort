program p
implicit none
integer::s
call get_command_argument(0,status=s)
if(s/=0) error stop 1
end program
