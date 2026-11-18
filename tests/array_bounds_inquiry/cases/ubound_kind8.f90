program main
implicit none
real::x(-2:0,5:6)
integer(8)::d
d=2
if(any(ubound(kind=8,array=x)/=[0_8,6_8])) error stop 1
if(ubound(kind=8,dim=d,array=x)/=6_8) error stop 2
if(kind(ubound(x,kind=8))/=8.or.kind(ubound(x,d,8))/=8) error stop 3
end program
