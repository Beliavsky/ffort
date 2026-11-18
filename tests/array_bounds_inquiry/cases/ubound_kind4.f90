program main
implicit none
real::x(-2:0,5:6)
integer(8)::d
d=2
if(any(ubound(kind=4,array=x)/=[0_4,6_4])) error stop 1
if(ubound(kind=4,dim=d,array=x)/=6_4) error stop 2
if(kind(ubound(x,kind=4))/=4.or.kind(ubound(x,d,4))/=4) error stop 3
end program
