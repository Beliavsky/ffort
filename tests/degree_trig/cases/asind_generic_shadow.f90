module m
interface asind
module procedure f
end interface
contains
integer function f(i)
integer,intent(in)::i
f=i+1
end function
end module
program p
use m
print *,asind(7)
end program
