program p
implicit none
real(8)::x(2)
x=[3d0,4d0]
if(norm2(x=x)/=5d0) error stop 1
end program
