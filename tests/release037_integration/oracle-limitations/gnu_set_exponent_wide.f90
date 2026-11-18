program probe
implicit none
integer(8)::i
real(8)::x(2),y(2)
i=-huge(0_8)
x=[1d0,-1d0]
y=set_exponent(x,i)
write(*,'(i0,2(1x,es24.16))')i,y
end program
