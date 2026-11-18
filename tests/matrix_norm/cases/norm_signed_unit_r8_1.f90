program p
implicit none
real(8)::x(1)
x=5.0_8
if(norm2(x)/=5.0_8) error stop 1
end program
