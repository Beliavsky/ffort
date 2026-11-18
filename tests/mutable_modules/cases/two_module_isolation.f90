module first
integer::counter=2
contains
function getone() result(r)
integer::r
r=counter
end function
end module
module second
integer::counter=9
contains
subroutine change()
counter=counter+1
end subroutine
function gettwo() result(r)
integer::r
r=counter
end function
end module
program main
use first,only:getone
use second,only:gettwo,change
call change()
print *,getone(),gettwo()
end program
