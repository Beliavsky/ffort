program p
implicit none
integer::a(0)
write(*,'(*(i0,1x))')size(eoshift(a,huge(0_8)))
end program
