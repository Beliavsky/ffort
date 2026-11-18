program p
implicit none
contains
simple subroutine q()
character(20)::v
call get_command_argument(0,value=v)
end subroutine
end program
