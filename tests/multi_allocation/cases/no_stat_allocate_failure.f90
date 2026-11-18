program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer::s
allocate(b(1))
print *,"before"
allocate(a(1),b(2),c(3))
print *,"after"
end program
