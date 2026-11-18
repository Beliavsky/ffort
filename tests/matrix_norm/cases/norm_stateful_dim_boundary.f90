program p
implicit none
real::x(2,3),v(3)
x=1
v=norm2(x,getdim())
if(any(abs(v-sqrt(2.))>2e-6)) error stop 1
if(getdim()/=2) error stop 2
contains
integer function getdim()
integer,save::calls=0
calls=calls+1
getdim=calls
end function
end program
