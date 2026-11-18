program p
implicit none
integer::x(3,2)
x=reshape([1,2,3,4,5,6],[3,2])
write(*,'(*(g0,1x))')x(3:1:-1,:)
end program
