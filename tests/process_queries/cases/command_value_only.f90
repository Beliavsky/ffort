program p
implicit none
character(11)::v
call get_command_argument(0,v)
if(v/='program.f90') error stop 1
end program
