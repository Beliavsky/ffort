module m
implicit none
contains
subroutine consume(a,b)
character(*),intent(in)::a(:)
character(*),intent(out)::b(:)
b="zz"
print "(a)",a
end subroutine
end module
program main
use m
implicit none
character(2)::x(-1:1)=['ab','cd','ef']
integer::i(4)=[1,-1,1,0]
character(2)::y(2)
call consume(x(i),y)
print "(a)",y
end program
