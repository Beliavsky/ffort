program p
implicit none
real::x
real(8)::y
x=nearest(0.,1.)
y=nearest(0d0,1d0)
write(*,'(*(g0,1x))')x,y
end program
