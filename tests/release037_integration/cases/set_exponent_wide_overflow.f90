program main
implicit none
real(8)::x
integer(8)::i
x=1d0
i=huge(0_8)
write(*,'(a)')"before"
print *,7,set_exponent(x,i)
end program
