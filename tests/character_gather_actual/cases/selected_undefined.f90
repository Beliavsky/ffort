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
character(2)::x(2)
print "(a)","SAFE"
call consume(x([1]))
end program
