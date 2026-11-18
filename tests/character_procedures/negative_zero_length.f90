module m
implicit none
contains
function make(n) result(y)
integer,intent(in)::n
character(n)::y(2)
y="x"
end function
end module m
program test
use m
implicit none
character(0)::a(2)
a=make(-9)
print *,len(a),size(a),a(1)//"|"
end program test
