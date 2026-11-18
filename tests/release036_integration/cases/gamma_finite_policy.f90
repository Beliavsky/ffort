program main
implicit none
real(8)::x
x=huge(0d0)
write(*,'(a)')"before"
write(*,'(i0,1x,es24.16)')7,log_gamma(x)
end program
