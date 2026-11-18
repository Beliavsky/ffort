module m
implicit none
contains
function tick() result(n)
integer,save::n=0
continue
end function
end module
program p
use m
implicit none
print *,tick()
end program
