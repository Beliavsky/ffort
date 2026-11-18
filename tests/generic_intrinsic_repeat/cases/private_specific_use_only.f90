module m
implicit none
private
public::repeat
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
print '(a)',repeat('ab',2),repeat(2,'ab')
end program
