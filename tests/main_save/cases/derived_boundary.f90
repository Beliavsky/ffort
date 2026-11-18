module m
implicit none
type t
integer::v
end type
end module
program p
use m
implicit none
type(t),save::a=t(1)
print *,1
end program
