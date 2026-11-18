program p
implicit none
real(4)::x(1)
x=5.0_4
if(norm2(x)/=5.0_4) error stop 1
end program
