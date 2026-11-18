program p
implicit none
real(4)::x(2,3)
integer::d
if(kind(norm2(x))/=4.or.kind(norm2(x,d))/=4) error stop 1
end program
