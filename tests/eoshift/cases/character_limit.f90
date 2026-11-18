program p
implicit none
character(65536)::a(1),b
a="A";b="B"
write(*,'(i0)')len(eoshift(a,1,b))
end program
