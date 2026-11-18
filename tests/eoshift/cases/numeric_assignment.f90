program p
implicit none
integer::a(3),b(3)
a=[1,2,3];b=eoshift(a,1,-1);a=eoshift(b,-1,-2)
write(*,'(*(i0,1x))')a
end program
