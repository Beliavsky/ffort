program p
implicit none
real::x(0,3),y(3,0),undefined
y=transpose(x+undefined)
if(size(y)/=0) error stop 1
end program
