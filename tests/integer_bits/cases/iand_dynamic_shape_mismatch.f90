program bits_driver
implicit none
integer,allocatable::a(:),b(:)
allocate(a(2),b(3))
a=1
b=1
print *,iand(a,b)
end program
