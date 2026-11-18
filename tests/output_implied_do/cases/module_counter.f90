module m
implicit none
integer::i
end module
program main
use m
implicit none
print *, (i,i=1,3)
end program
