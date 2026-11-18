program p
implicit none
character(2)::a(0)
write(*,'(2(i0,1x))')size(eoshift(a,1)),len(eoshift(a,1))
end program
