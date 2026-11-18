program p
implicit none
integer(8)::x(3),ix(2),y(0)
y=x([integer::])
write(*,'(3i3)')size(y),kind(x(ix)),count(y==0_8)
end program
