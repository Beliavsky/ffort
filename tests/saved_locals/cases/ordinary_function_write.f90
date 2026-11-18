module m
implicit none
contains
integer function tick() result(v)
integer,save::n=0
n=n+1
v=n
end function
end module
program p
use m
implicit none
print *,tick()
end program
