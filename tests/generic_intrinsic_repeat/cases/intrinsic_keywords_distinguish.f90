module m
implicit none
interface repeat
module procedure custom
end interface
contains
function custom(text,n) result(answer)
character(*),intent(in)::text
integer,intent(in)::n
character(4)::answer
answer='USER'
end function
end module
program main
use m
implicit none
print '(a)',repeat(string='ab',ncopies=3)
end program
