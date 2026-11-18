program probe
implicit none
integer :: a(2),x,b(-1:0),y
x=7
y=9
a(1)=x
a(2)=y
b(-1)=a(2)
b(0)=a(1)
print *,a(1),a(2),b(-1),b(0),x,y
end program probe
