module m
implicit none
integer,parameter::n=4
end module
program p
use m,only:k=>n
implicit none
print *,k
end program
