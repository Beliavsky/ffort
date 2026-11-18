module m
implicit none
contains
subroutine work(n)
integer,intent(in)::n
character(max(1,(n+2)*2-3))::a
character(-n**2)::b
character(2**n)::c
print *,len(a),len(b),len(c)
end subroutine
end module m
program test
use m
implicit none
integer::n
n=4
call work(n)
end program test
