module m
implicit none
contains
integer function tick() result(v)
integer,save::n=0
v=n+3
end function
end module
program p
use m
implicit none
print *,tick(),tick()
end program
