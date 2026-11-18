program p
implicit none
real(8)::a(3),b
a=[-0.0_8,0.0_8,-3.25_8];b=-0.0_8
write(*,'(*(f10.2,1x))')eoshift(a,-1,b)
end program
