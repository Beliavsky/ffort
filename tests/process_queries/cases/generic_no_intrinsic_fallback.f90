module m
implicit none
interface get_command_argument
module procedure q
end interface
contains
subroutine q(flag)
logical,intent(in)::flag
end subroutine
end module
program p
use m
implicit none
integer::n
call get_command_argument(0,length=n)
end program
