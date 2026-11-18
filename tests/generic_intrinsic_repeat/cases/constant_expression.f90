module m
implicit none
interface repeat
module procedure custom
end interface
contains
function custom(n,text) result(answer)
integer,intent(in)::n
character(*),intent(in)::text
character(4)::answer
answer='USER'
end function
end module
program main
use m
implicit none
character(3),parameter::text=repeat('x',3)
print '(a)',text
end program
