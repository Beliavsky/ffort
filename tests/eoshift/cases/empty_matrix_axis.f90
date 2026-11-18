program p
implicit none
integer::a(0,3)
write(*,'(*(i0,1x))')size(eoshift(a,[1,2,3],boundary=[4,5,6]))
end program
