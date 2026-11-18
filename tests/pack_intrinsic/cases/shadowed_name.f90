module m
implicit none
contains
pure integer function pack(x)
integer,intent(in)::x
pack=x+1
end function
end module
program main
use m
implicit none
print *,pack(4)
end program
