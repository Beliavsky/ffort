module m
implicit none
contains
integer function host() result(y)
y=3
y=child()
contains
integer function child() result(z)
z=y+2
end function
end function
end module
program p
use m
implicit none
print *,host()
end program
