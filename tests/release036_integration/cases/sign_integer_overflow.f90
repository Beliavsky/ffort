program main
implicit none
integer(8)::x
x=-huge(0_8)
x=x-1_8
write(*,'(a)')"before"
write(*,'(2(i0,1x))')7,sign(x,1_8)
end program
