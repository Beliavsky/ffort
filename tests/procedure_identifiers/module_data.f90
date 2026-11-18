module m
implicit none
integer,parameter::procedure=7
end module
program p
use m,only:procedure
implicit none
if(procedure/=7) error stop 1
print *, 'module data'
end program
