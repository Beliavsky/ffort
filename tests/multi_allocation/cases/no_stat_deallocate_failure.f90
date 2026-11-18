program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer::s
allocate(a(1),c(1))
print *,"before"
deallocate(a,b,c)
print *,"after"
end program
