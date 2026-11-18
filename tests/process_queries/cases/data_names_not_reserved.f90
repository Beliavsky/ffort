program p
implicit none
integer::getcwd,get_command_argument
getcwd=4
get_command_argument=5
if(getcwd+get_command_argument/=9) error stop 1
end program
