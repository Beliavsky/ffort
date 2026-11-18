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
print *, 91,a(-3:3:2147483647),92
end program probe
