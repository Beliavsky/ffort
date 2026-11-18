module m
implicit none
contains
subroutine host(values,last)
integer,intent(out)::values(3),last
integer::counter
counter=0
values=next_value([10,10,10])
last=counter
contains
impure elemental integer function next_value(x) result(y)
integer,intent(in)::x
counter=counter+1
y=x+counter
end function
end subroutine
end module
program p
use m
implicit none
integer::values(3),last
call host(values,last)
print *,values,last
end program
