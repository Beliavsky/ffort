program probe
implicit none
integer :: a(1:5)
a(1)=2
a(2)=4
a(3)=6
a(4)=8
a(5)=10
print *, a(a(1):a(2):a(1))
end program probe
