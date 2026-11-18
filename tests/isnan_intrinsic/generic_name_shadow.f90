module m
implicit none
interface isnan
module procedure predicate
end interface
contains
logical function predicate(x)
integer,intent(in)::x
predicate=x==2
end function
end module
program p
use m
implicit none
print *,isnan(2)
end program
