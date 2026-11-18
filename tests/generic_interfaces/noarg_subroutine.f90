module operations
implicit none
interface hello
module procedure greet
end interface
contains
subroutine greet()
print *,42
end subroutine
end module
program main
use operations
implicit none
call hello()
end program
