module state
integer::counter=0
contains
impure elemental function next_value(x) result(r)
integer,intent(in)::x
integer::r
counter=counter+1
r=counter+x
end function
end module
program main
use state
integer::values(3)
values=next_value([10,20,30])
print *,counter,values
end program
