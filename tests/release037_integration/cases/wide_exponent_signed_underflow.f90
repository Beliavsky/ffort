program main
implicit none
real(8)::x(2),y(2)
integer(8)::n
x=[1d0,-1d0]
n=-huge(0_8)
y=set_exponent(x,n)
write(*,'("wide:",5(1x,i0))')int(sign(1d0,y)),count(y==0d0), &
int(sign(1d0,set_exponent(-0d0,huge(0_8)))),kind(exponent(y))
end program
