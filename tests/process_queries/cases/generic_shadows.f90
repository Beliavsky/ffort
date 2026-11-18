module m
implicit none
interface getcwd
module procedure a
end interface
interface get_command_argument
module procedure b
end interface
contains
subroutine a(x)
integer,intent(out)::x
x=8
end subroutine
subroutine b(x)
integer,intent(out)::x
x=10
end subroutine
end module
program p
use m
implicit none
integer::n
call getcwd(n)
if(n/=8) error stop 1
call get_command_argument(n)
if(n/=10) error stop 2
end program
