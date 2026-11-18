program p
implicit none
integer::n
call getcwd(n)
if(n/=7) error stop 1
call get_command_argument(n)
if(n/=9) error stop 2
contains
subroutine getcwd(x)
integer,intent(out)::x
x=7
end subroutine
subroutine get_command_argument(x)
integer,intent(out)::x
x=9
end subroutine
end program
