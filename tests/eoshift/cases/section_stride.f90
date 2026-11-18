program p
implicit none
integer::a(3,4),i
a=reshape([(i,i=1,12)],[3,4])
write(*,'(*(i0,1x))')eoshift(a(3:1:-1,4:1:-2),[-1,1,2],boundary=[-3,-2,-1],dim=2)
end program
