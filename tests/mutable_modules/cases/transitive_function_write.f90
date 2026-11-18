module state
integer::counter=0
contains
function value() result(r)
integer::r
call change()
r=counter
end function
subroutine change()
counter=counter+1
end subroutine
end module
program main
use state
print *,value()
end program
