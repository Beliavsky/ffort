program main
implicit none
real(8)::x(2)
x(1)=1d0
write(*,'(a)')"before"
print *,7,count(isnan(x))
end program
