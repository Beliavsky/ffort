program p
implicit none
integer::a(3)
a=[1,2,3]
write(*,'(*(i0,1x))')eoshift(a,8)
end program
