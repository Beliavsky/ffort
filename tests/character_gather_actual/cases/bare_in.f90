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
character(2)::x(-1:1)=['ab','cd','ef']
integer::i(4)=[1,-1,1,0]
call consume(x(i))
end program
