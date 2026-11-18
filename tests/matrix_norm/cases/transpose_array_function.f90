program p
implicit none
real::v(3,2)
v=transpose(values())
if(any(v/=1.)) error stop 1
contains
function values() result(x)
real::x(2,3)
x=1
end function
end program
