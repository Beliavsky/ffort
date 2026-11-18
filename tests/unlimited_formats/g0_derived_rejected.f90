module m
implicit none
type :: t
integer::n
end type
end module
program p
use m
implicit none
type(t)::x
write(*,'(*(g0))')x
end program
