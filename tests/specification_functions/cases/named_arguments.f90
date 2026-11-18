module m
implicit none
contains
pure integer function f(n,k) result(v)
integer,intent(in)::n,k
v=n+k
end function
subroutine run(n)
integer,intent(in)::n
integer::a(f(k=2,n=n))
character(len=f(k=2,n=n))::s
a=1
s='abcdefgh'
print *,size(a),len(s),s
end subroutine
end module
program p
use m
implicit none
call run(3)
end program
