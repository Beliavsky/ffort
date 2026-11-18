module m
implicit none
contains
subroutine consume(v)
character(*),intent(in)::v(:)
print "(a)",v
end subroutine
end module
program main
use m
implicit none
character(0)::x(2)
x=""
call consume(x([2,1,2]))
end program
