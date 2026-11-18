program main
implicit none
real::x(-2:0,5:6)
integer(8)::d
d=2
if(any(lbound(kind=4,array=x)/=[-2_4,5_4])) error stop 1
if(lbound(kind=4,dim=d,array=x)/=5_4) error stop 2
if(kind(lbound(x,kind=4))/=4.or.kind(lbound(x,d,4))/=4) error stop 3
end program
