program probe
implicit none
integer, parameter :: low=-3, high=3, stride=2
integer :: a(-3:3)
a(-3)=-30
a(-2)=-20
a(-1)=-10
a(0)=0
a(1)=10
a(2)=20
a(3)=30
print *, a(low:high:stride)
end program probe
