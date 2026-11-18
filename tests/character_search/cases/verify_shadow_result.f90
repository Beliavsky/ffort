module m
contains
integer function f(x) result(verify)
integer,intent(in)::x
verify=x+1
end function
end module
program p
use m
implicit none
print *,f(9)
end program
