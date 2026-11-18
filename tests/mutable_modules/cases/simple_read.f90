module state
implicit none
integer::counter=2
contains
simple function change() result(answer)
integer::answer
answer=counter
end function
end module
program main
use state
implicit none
print *,change()
end program
