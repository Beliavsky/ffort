program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer::s
allocate(a(500001),b(500000),c(1),stat=s)
print *,s>0,allocated(a),allocated(b),allocated(c),size(a)
end program
