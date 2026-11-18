module a
contains
function fa(x) result(y)
integer,intent(in) :: x
integer :: y
y=x+1
end function fa
end module a
module b
contains
function fb(x) result(y)
integer,intent(in) :: x
integer :: y
y=x*2
end function fb
end module b
program main
use a
use b
print *, fa(3),fb(3)
end program main
