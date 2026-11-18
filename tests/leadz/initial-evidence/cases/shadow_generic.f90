module m
interface leadz
module procedure ours
end interface
contains
function ours(i) result(x)
integer(8),intent(in)::i
integer(8)::x
x=i+100_8
end function
end module
program p
use m
implicit none
print *,leadz(1_8)
end program
