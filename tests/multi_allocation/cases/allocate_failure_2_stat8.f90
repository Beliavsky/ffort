program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer(8)::s
allocate(c(4))
c=9
allocate(a(1),b(2),c(3),stat=s)
print *,s>0,allocated(a),allocated(b),allocated(c),size(c),sum(c)
end program
