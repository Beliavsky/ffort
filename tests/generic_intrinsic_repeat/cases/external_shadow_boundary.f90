module m
implicit none
end module
program main
use m
implicit none
character(4),external::repeat
print '(a)',repeat('ab',3)
end program
function repeat(text,n) result(answer)
character(*),intent(in)::text
integer,intent(in)::n
character(4)::answer
answer='USER'
end function
