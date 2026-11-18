module m
implicit none
interface repeat
module procedure custom
end interface
contains
function custom(string,ncopies) result(answer)
character(*),intent(in)::string
integer,intent(in)::ncopies
character(4)::answer
answer='USER'
end function
end module
program main
use m
implicit none
print '(a)',repeat(ncopies=3,string='ab')
end program
