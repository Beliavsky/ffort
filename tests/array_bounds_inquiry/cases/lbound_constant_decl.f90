program main
implicit none
real::x(-2:0,5:6)
integer(8),parameter::b(2)=lbound(x,kind=8)
integer,parameter::c=lbound(x,2)
if(any(b/=[-2_8,5_8]).or.c/=5) error stop 1
end program
