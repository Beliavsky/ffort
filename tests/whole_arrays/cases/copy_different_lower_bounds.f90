program probe
implicit none
integer :: a(-2:1), b(7:10)
a(-2)=2
a(-1)=-3
a(0)=7
a(1)=0
b=a
print *, b,b(7),b(10)
end program probe
