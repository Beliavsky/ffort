program probe
implicit none
integer :: a(3),b(3)
a=2
b=1
b(2)=0
print *, 71
print *, a(:)/b(3:1:-1)
end program probe
