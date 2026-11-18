program p
implicit none
integer,parameter::rk=8
real::x(-2:0,5:6)
integer(8)::b(2)
b=lbound(x,kind=kind(0_8))
if(kind(lbound(x,kind=kind(0_8)))/=8)error stop 1
if(any(b/=[-2_8,5_8]))error stop 2
end program
