program main
real::x(-2:0,5:6)
integer::a(3)
a=[1,2,3]+lbound(x,2)
if(any(a/=[6,7,8])) error stop 1
end program
