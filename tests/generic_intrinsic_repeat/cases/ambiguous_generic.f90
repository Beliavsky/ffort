module m
implicit none
interface repeat
module procedure custom,custom_two
end interface
contains
function custom(text,n) result(answer)
character(*),intent(in)::text
integer,intent(in)::n
character(4)::answer
answer='USER'
end function
function custom_two(text,n) result(answer)
character(*),intent(in)::text
integer,intent(in)::n
character(4)::answer
answer='USER'
end function
end module
program main
use m
implicit none
print '(a)',repeat('ab',3)
end program
