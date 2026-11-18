module m
implicit none
contains
pure integer function f(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine run(n)
integer,intent(in)::n
integer::a(-f(n):f(f(n))+1,f(n)-1)
a=1
print *,lbound(a,1),ubound(a,1),shape(a),sum(a)
end subroutine
end module
program p
use m
implicit none
call run(3)
end program
