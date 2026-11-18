module m
interface random_seed
module procedure seed
end interface
contains
pure subroutine seed(x)
integer,intent(out)::x
x=7
end subroutine
end module
program p
use m
implicit none
integer::x
call random_seed(x)
print *,x
end program
