module m
implicit none
character(2)::x(2)=["ab","cd"]
contains
subroutine consume(v)
character(*),intent(in)::v(:)
print "(a)",v,x
end subroutine
end module
program main
use m
implicit none
call consume(x([2,1]))
end program
