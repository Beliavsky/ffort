program p
implicit none
integer::a(3)
a=[1,2,3]
write(*,'(a)',advance='no')'kept:'
write(*,'(2i3)')a([1,4])
end program
