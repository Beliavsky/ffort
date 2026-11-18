module m
type t
integer::i
end type
end module
program p
use m
type(t)::a
a%i=1
print *,not(a%i)
end program
