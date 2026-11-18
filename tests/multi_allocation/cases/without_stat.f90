program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer::s
allocate(a(1),b(2),c(3))
a=1
b=2
c=3
print *,sum(a),sum(b),sum(c)
deallocate(a,b,c)
print *,allocated(a),allocated(b),allocated(c)
end program
