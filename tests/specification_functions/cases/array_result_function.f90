module m
implicit none
contains
pure integer function f(n) result(v)
integer,intent(in)::n
v=n+1
end function
function run(n) result(a)
integer,intent(in)::n
integer::a(f(n))
a=7
end function
end module
program p
use m
implicit none
print *,run(3)
end program
