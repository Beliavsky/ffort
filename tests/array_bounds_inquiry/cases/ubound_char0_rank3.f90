program main
implicit none
character(0)::x(-2:0,5:6,-5:-4)
if(any(ubound(x)/=[0,6,-4])) error stop 1
if(size(ubound(x))/=3.or.kind(ubound(x))/=4) error stop 2
end program
