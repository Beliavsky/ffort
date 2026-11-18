program main
implicit none
real(4)::x
x=huge(0.0)
write(*,'(a)')"before"
print *,7,nearest(x,1.0)
end program
