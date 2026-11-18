program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer::s
allocate(a(65536),b(65536),c(0),stat=s)
print *,s,allocated(a),allocated(b),allocated(c),size(a)+size(b)
end program
