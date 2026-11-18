program main
implicit none
logical::x(-2:0,5:6,-5:-4)
if(any(lbound(x)/=[-2,5,-5])) error stop 1
if(size(lbound(x))/=3.or.kind(lbound(x))/=4) error stop 2
end program
