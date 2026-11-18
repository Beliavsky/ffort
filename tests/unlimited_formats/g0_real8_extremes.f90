program p
implicit none
real(8)::x(6)
x=[0d0,-0d0,tiny(0d0),huge(0d0),1.25d0,-2.5d0]
write(*,'(*(g0,1x))')x
end program
