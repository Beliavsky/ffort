program p
implicit none
real(8)::x(3),y(3)
integer::i
x=[-huge(0d0),0d0,2d0]
y=7d0
forall(i=1:3,x(i)>=0d0) y(i)=erfc_scaled(x(i))
print *,y
end program
