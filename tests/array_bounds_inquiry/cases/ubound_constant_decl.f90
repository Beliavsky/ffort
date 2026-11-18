program main
implicit none
real::x(-2:0,5:6)
integer(8),parameter::b(2)=ubound(x,kind=8)
integer,parameter::c=ubound(x,2)
if(any(b/=[0_8,6_8]).or.c/=6) error stop 1
end program
