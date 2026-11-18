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
character(2),parameter::x(3)=['ab','cd','ef']
call consume(x([3,1]))
end program
