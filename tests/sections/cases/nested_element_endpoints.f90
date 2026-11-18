program probe
implicit none
integer :: indexes(2)
integer :: a(1:5)
a(1)=2
a(2)=4
a(3)=6
a(4)=8
a(5)=10
indexes(1)=1
indexes(2)=2
print *, a(a(indexes(1)):a(indexes(2)))
end program probe
