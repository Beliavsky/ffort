program probe
implicit none
integer, allocatable :: a(:),b(:)
a=[1,2]
allocate(b(3))
b(1)=3
a=b
end program
