program p
implicit none
real::x(-2:0,5:6)
integer,parameter::v(2)=ubound((x))
if(any(v/=[3,2]))error stop 1
end program
