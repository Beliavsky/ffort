program p
implicit none
integer::i
real(8)::x(3),y(3)
x=[1d0,0d0,2d0]
y=0d0
forall(i=1:3,x(i)>0d0) y(i)=bessel_yn(2,x(i))
print *,y
end program
