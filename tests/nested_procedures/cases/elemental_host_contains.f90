module m
implicit none
contains
elemental integer function host(x) result(y)
integer,intent(in)::x
y=child()
contains
pure integer function child() result(z)
z=x+1
end function
end function
end module
program p
use m
implicit none
print *,host(2)
end program
