program p
implicit none
call q()
contains
subroutine q()
character(20)::v='old'
call get_command_argument(0,value=v)
end subroutine
end program
