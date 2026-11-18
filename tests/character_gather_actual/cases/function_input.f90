module m
implicit none
contains
function first(v) result(answer)
character(*),intent(in)::v(:)
character(2)::answer
answer=v(1)
end function
end module
program main
use m
implicit none
character(2)::x(-1:1)=['ab','cd','ef']
integer::i(4)=[1,-1,1,0]
print "(a)",first(x(i))
end program
