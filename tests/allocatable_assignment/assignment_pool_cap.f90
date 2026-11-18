program probe
implicit none
integer,allocatable :: a(:),b(:)
a=[1]
allocate(b(500001))
b=1
a=b
end program
