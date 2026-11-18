module procedure
implicit none
integer,parameter::x=7
end module
program p
use procedure,only:x
implicit none
if(x/=7) error stop 1
print *, 'module name'
end program
