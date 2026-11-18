program probe
implicit none
integer :: b(8:10)
integer :: a(-3:3)
a(-3)=-30
a(-2)=-20
a(-1)=-10
a(0)=0
a(1)=10
a(2)=20
a(3)=30
b=7
a(3:-1:-2)=b
print *, a
end program probe
