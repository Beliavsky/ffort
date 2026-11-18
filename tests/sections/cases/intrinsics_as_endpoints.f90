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
print *, a(min(-2,-1):max(1,2):abs(-2))
end program probe
