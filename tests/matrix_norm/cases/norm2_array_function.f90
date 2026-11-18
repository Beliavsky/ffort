program p
implicit none
real::v
v=norm2(values())
if(abs(v-sqrt(6.))>2e-6) error stop 1
contains
function values() result(x)
real::x(2,3)
x=1
end function
end program
