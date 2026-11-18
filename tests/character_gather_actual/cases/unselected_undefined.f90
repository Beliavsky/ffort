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
character(2)::x(3)
x(2)="cd"
call consume(x([2,2]))
end program
