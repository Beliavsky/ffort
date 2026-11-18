program main
implicit none
integer(8)::x
x=huge(0_8)
write(*,'(a)')"before"
write(*,'(2(i0,1x))')7,dim(x,-1_8)
end program
