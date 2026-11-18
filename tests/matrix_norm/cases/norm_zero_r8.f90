program p
implicit none
real(8)::x(3)
x=[-0d0,0d0,-0d0]
if(norm2(x)/=0d0) error stop 1
end program
