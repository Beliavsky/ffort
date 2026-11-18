program p
implicit none
integer::a(3),i
a=[1,2,3]
write(*,'(3i3)')(sum(a([i,1])),i=1,3)
end program
