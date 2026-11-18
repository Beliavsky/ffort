module state
implicit none
private
public::change,get
integer::counter=1
contains
subroutine change()
counter=counter+1
end subroutine
function get() result(r)
integer::r
r=counter
end function
end module
program main
use state
implicit none
call change()
print *,get()
end program
