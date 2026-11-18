module m
implicit none
integer::offset
contains
pure integer function f(n) result(v)
integer,intent(in)::n
v=n+offset
end function
subroutine run(n)
integer,intent(in)::n
integer::a(f(n))
a=1
offset=9
print *,size(a)
end subroutine
end module
program p
use m
implicit none
offset=2
call run(3)
call run(3)
end program
