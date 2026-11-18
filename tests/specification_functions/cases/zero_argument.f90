module m
implicit none
contains
pure integer function f() result(v)
v=2
end function
subroutine run(n)
integer,intent(in)::n
integer::a(f())
character(len=f())::s
a=1
s='abc'
print *,size(a),s
end subroutine
end module
program p
use m
implicit none
call run(3)
end program
