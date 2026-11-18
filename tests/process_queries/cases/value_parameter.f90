program p
implicit none
character(3),parameter::v='abc'
call get_command_argument(0,v)
end program
