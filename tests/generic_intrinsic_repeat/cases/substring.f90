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
character(4)::text
text='abcd'
print '(a)',repeat(text(2:3),2)
end program
