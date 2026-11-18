program probe
implicit none
integer :: indexes(3)
integer :: a(1:5)
a(1)=1
a(2)=2
a(3)=3
a(4)=4
a(5)=5
indexes(1)=5
indexes(2)=1
indexes(3)=-2
print *, a(indexes(1):indexes(2):indexes(3))
end program probe
