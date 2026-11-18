module state
implicit none
integer::counter=8
contains
pure function change() result(answer)
integer::answer
answer=counter
end function
end module
program main
use state
implicit none
print *,change()
counter=9
print *,change()
end program
