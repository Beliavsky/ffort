program p
implicit none
character(20)::v
call q()
contains
subroutine q()
call get_command_argument(0,value=v)
end subroutine
end program
