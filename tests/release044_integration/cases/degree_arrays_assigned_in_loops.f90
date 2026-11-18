program p
implicit none
real(8)::a(3),b(3),x(3),y(3)
character(32)::fmt
integer::i
x=[0d0,30d0,90d0]
y=[0d0,60d0,180d0]
do i=1,3
a(i)=sind(x(i))
b(i)=cosd(y(i))
end do
fmt='(*(f5.1))'
write(*,fmt)(a(i),b(i),i=1,3)
end program
