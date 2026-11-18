program p
implicit none
real::a(3)
a=[0.25,0.5,0.75]
write(*,'(*(f10.2,1x))')eoshift(a,0)
end program
