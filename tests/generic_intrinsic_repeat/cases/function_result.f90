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
print '(a)',repeat(get_text(),2)
contains
function get_text() result(x)
character(2)::x
x='ab'
end function
end program
