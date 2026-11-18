program p
implicit none
integer,parameter::rk=8
real::x(-2:0,5:6)
integer(8)::b(2)
b=ubound(x,kind=4+4)
if(kind(ubound(x,kind=4+4))/=8)error stop 1
if(any(b/=[0_8,6_8]))error stop 2
end program
