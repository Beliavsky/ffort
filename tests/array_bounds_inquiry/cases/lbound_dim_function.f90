program p
implicit none
real::x(-2:0,5:6)
integer::v(2)
v=[10,20]+lbound(x,dim=next())
if(any(v/=[15,25]))error stop 2
contains
integer function next()result(d)
d=2
end function
end program
