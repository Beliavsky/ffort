program p
implicit none
character(20)::v
call q(v)
contains
subroutine q(v)
character(20),intent(out),optional::v
call get_command_argument(0,value=v)
end subroutine
end program
