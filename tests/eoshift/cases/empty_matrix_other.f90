program p
implicit none
integer::a(2,0),s(0),b(0)
write(*,'(*(i0,1x))')size(eoshift(a,s,boundary=b))
end program
