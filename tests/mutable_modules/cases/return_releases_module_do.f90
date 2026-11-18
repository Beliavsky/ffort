module state
integer::counter
contains
subroutine change()
do counter=1,3
return
end do
end subroutine
end module
program main
use state
call change()
counter=9
print *,counter
call change()
print *,counter
end program
