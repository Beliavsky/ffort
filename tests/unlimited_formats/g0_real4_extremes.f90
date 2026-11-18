program p
implicit none
real::x(6)
x=[0.,-0.,tiny(0.),huge(0.),1.25,-2.5]
write(*,'(*(g0,1x))')x
end program
