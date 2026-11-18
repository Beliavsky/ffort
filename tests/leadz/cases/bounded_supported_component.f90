module m
implicit none
type :: t
integer :: a
end type
end module
program p
use m
implicit none
type(t)::x
x%a=1
print *,leadz(x%a)
end program
