module m
implicit none
contains
impure elemental integer function f(x) result(r)
integer,intent(in)::x
print *,'selector'
r=x
end function
end module
program p
use m
implicit none
select case(f(2))
case(0)
print *,0
case(1)
print *,1
case(2)
print *,2
case default
print *,-1
end select
end program
