module first
integer::counter=1
end module
module second
integer::counter=2
end module
program main
use first
use second
print *,counter
end program
