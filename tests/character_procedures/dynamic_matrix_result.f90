module m
implicit none
contains
function make(x) result(y)
character(*),intent(in)::x
character(len(x)+1)::y(2,2)
y="!"//x
end function
end module m
program test
use m
implicit none
character(4)::a(2,2)
a=make("xy")
print *,a(1,1)//"|",a(2,2)//"|",len(a)
end program test
