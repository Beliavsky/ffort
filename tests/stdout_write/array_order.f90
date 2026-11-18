program main
implicit none
integer::a(2,3)
a=reshape([1,2,3,4,5,6],[2,3])
write(*,'(6(i0,1x))') a
end program
