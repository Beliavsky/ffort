module m
implicit none
contains
pure integer function f(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine run(n)
integer,intent(inout)::n
integer::a(f(n))
character(len=f(n))::s
a=9
s='abcdefgh'
n=n+5
print *,size(a),len(s),s,n
end subroutine
end module
program p
use m
implicit none
integer::n
n=3
call run(n)
end program
