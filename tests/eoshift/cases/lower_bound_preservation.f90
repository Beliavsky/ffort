program p
implicit none
integer::a(-2:0),b(4:6)
a=[1,2,3];b=eoshift(a,-1,-9)
write(*,'(5(i0,1x))')lbound(b),ubound(b),b
end program
