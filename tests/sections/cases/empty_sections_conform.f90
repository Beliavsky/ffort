program probe
implicit none
integer :: a(-3:3)
a(-3)=-30
a(-2)=-20
a(-1)=-10
a(0)=0
a(1)=10
a(2)=20
a(3)=30
a(3:-3)=a(-3:3:-1)
print *, a
end program probe
