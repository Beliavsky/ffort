program main
implicit none
integer::a(2,2)
a=1
a([2,1],:)=2
write(*,'(i0)')sum(a)
end program
