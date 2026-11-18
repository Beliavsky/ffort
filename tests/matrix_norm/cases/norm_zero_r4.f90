program p
implicit none
real(4)::x(3)
x=[-0.0,0.0,-0.0]
if(norm2(x)/=0.0) error stop 1
end program
