module m
implicit none
contains
function repeat(text,n) result(answer)
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
