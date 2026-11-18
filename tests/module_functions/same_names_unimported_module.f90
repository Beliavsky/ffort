module a
contains
function f(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+1
end function f
end module a
module b
contains
function f(x) result(y)
integer,intent(in) :: x
integer :: y
y=x*2
end function f
end module b
program main
use a
print *, f(3)
end program main
