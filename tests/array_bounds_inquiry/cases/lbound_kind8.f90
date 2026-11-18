program main
implicit none
real::x(-2:0,5:6)
integer(8)::d
d=2
if(any(lbound(kind=8,array=x)/=[-2_8,5_8])) error stop 1
if(lbound(kind=8,dim=d,array=x)/=5_8) error stop 2
if(kind(lbound(x,kind=8))/=8.or.kind(lbound(x,d,8))/=8) error stop 3
end program
