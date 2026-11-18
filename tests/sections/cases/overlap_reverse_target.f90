program probe
implicit none
integer :: a(1:5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
a(5:1:-1)=a(:)
print *, a
end program probe
