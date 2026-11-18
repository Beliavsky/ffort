program p
implicit none
integer::a(2,3)
a=reshape([1,2,3,4,5,6],[2,3])
write(*,'(*(i0,1x))')eoshift(dim=2,array=a,shift=[-1,2])
end program
