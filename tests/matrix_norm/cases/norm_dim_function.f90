program p
implicit none
real::x(2,3),v(3)
x=1
v=norm2(x,getdim())
if(any(abs(v-sqrt(2.))>2e-6)) error stop 1
contains
integer function getdim()
getdim=1
end function
end program
