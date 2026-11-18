program p
implicit none
integer::a(2,3),d
a=reshape([1,2,3,4,5,6],[2,3]);d=2
write(*,'(*(i0,1x))')eoshift(a,[-1,2],boundary=[-8,-9],dim=d)
end program
