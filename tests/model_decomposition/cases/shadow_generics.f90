module m
implicit none
interface fraction
module procedure f0
end interface
interface exponent
module procedure f1
end interface
interface set_exponent
module procedure f2
end interface
interface iachar
module procedure f3
end interface
contains
integer function f0(a) result(r)
integer,intent(in)::a
r=a+0
end function
integer function f1(a) result(r)
integer,intent(in)::a
r=a+1
end function
integer function f2(a) result(r)
integer,intent(in)::a
r=a+2
end function
integer function f3(a) result(r)
integer,intent(in)::a
r=a+3
end function
end module
program p
use m
implicit none
print *,fraction(1),exponent(1),set_exponent(1),iachar(1)
end program
