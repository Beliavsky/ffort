module composition
implicit none
contains
subroutine host(a,total)
integer,intent(out)::a(3),total
integer::counter,offset
counter=0
offset=10
a=next([1,2,3])
total=peek()
contains
impure elemental integer function next(x) result(y)
integer,intent(in)::x
counter=counter+1
y=x+offset+counter
end function
pure integer function peek() result(y)
y=counter+offset
end function
end subroutine
end module
program main
use composition
implicit none
integer::a(3),total
call host(a,total)
write(*,'("effects:",4(1x,i0))')a,total
call host(a,total)
write(*,'("reset:",4(1x,i0))')a,total
end program
