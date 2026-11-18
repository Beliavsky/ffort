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
print *, 1,a(2147483647:(-2147483647-1)),2
print *, 3,a((-2147483647-1):2147483647:-1),4
end program probe
