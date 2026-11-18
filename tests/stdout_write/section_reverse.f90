program main
implicit none
integer::a(5)
a=[1,2,3,4,5]
write(*,*)a(5:1:-2)
end program
