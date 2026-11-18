program p
implicit none
character(len=*),parameter :: fmt='(4(f10.6,1x))'
real(kind=8)::x(4),y(4)
x=[-1.0_8,0.0_8,1.0_8,0.0_8]
y=[0.0_8,1.0_8,0.0_8,-1.0_8]
print fmt,atan2(x=x,y=y)
print fmt,atan(x=x,y=y)
end program
