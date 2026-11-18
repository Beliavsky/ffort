module m
implicit none
character(20)::v
end module
program p
use m
implicit none
call get_command_argument(0,value=v)
end program
