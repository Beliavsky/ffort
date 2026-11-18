module state
integer,private::counter=2
end module
program main
use state
implicit none
print *,counter
end program
