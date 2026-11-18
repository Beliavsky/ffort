program p
implicit none
real(8)::a(3)
a=[0.25_8,0.5_8,0.75_8]
write(*,'(*(f10.2,1x))')eoshift(a,-2)
end program
