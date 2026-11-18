program p
implicit none
real(8)::x(2,3)
if(kind(norm2(x+1d0))/=8) error stop 1
end program
