program p
implicit none
real::x(-2:0,5:6)
integer::a(0),b(0)
b=a+sum(ubound(x))
if(size(b)/=0)error stop 1
end program
