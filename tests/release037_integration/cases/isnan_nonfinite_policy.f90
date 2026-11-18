program main
implicit none
real(8)::x
x=huge(0d0)
write(*,'(a)')"before"
print *,7,count([isnan(x*2d0)])
end program
