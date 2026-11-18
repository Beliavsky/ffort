program p
implicit none
real::v
v=norm2(values())
if(abs(v-sqrt(6.))>2e-6) error stop 1
if(any(values()/=2.)) error stop 2
contains
function values() result(x)
real::x(2,3)
integer,save::calls=0
calls=calls+1
x=calls
end function
end program
