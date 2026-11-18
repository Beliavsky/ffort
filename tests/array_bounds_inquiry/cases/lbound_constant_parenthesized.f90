program p
implicit none
real::x(-2:0,5:6)
integer,parameter::v(2)=lbound((x))
if(any(v/=[1,1]))error stop 1
end program
