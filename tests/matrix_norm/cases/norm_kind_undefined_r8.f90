program p
implicit none
real(8)::x(2,3)
integer::d
if(kind(norm2(x))/=8.or.kind(norm2(x,d))/=8) error stop 1
end program
