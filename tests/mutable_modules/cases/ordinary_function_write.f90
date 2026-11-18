module state
implicit none
integer::counter=2
contains
function change() result(answer)
integer::answer
counter=3
answer=counter
end function
end module
program main
use state
implicit none
print *,change()
end program
