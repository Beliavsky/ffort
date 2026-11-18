program probe
implicit none
integer :: a(1:5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
print *, a(1:3)+a(5:3:-1),a(1:3)-a(5:3:-1),a(1:3)*a(5:3:-1)
print *, 12/a(1:3),2**a(1:3),-a(1:3)**2
end program probe
