program p
implicit none
integer::a(5)
a=7
write(*,'("P",2(i0:,";"),:"END")')a
end program
