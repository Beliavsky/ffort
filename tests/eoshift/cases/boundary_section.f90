program p
implicit none
integer::a(3,2),b(6)
a=reshape([1,2,3,4,5,6],[3,2]);b=[-1,-2,-3,-4,-5,-6]
write(*,'(*(i0,1x))')eoshift(a,1,b(6:2:-2),dim=2)
end program
