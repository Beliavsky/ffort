program p
implicit none
integer::a(3)
a=[1,2,3]
a([1,3])=7
write(*,'(3i3)')a
end program
