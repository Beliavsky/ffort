program p
implicit none
integer::i
real(8)::x,y(7)
real::a,b(7)
do i=-52,61
 x=2.0d0**i
 y=[x-0.5d0,x-0.25d0,x,x+0.25d0,x+0.5d0,0.49d0*x,0.51d0*x]
 print *,nint(y,8),floor(y,8),ceiling(y,8)
 print *,nint(-y,8),floor(-y,8),ceiling(-y,8)
end do
do i=-24,29
 a=2.0**i
 b=[a-0.5,a-0.25,a,a+0.25,a+0.5,0.49*a,0.51*a]
 print *,nint(b,8),floor(b,8),ceiling(b,8)
 print *,nint(-b,8),floor(-b,8),ceiling(-b,8)
end do
end program
