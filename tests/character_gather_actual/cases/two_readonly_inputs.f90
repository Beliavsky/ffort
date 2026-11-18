module m
implicit none
contains
subroutine consume(a,b)
character(*),intent(in)::a(:),b(:)
print "(a)",a,b
end subroutine
end module
program main
use m
implicit none
character(2)::x(-1:1)=['ab','cd','ef']
integer::i(4)=[1,-1,1,0]
call consume(x(i),x([0,1]))
end program
