module m
implicit none
contains
pure integer function host(x) result(y)
integer,intent(in)::x
y=child(3)
contains
pure integer function child(z) result(v)
integer,intent(in)::z
v=x+z
end function
end function
end module
program p
use m
implicit none
print *,host(7)
end program
