module record_types
implicit none
type::pair
real(8)::a,b
end type
end module
program p
use record_types
implicit none
type(pair)::x,y
x=pair(-0.0d0,2.0d0)
y=x
x%b=3.0d0
print *,y%a,y%b,x%b
end program
