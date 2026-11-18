program main
implicit none
real(8)::x,s
x=1d0
s=-0d0
write(*,'(a)')"before"
print *,7,nearest(x,s)
end program
