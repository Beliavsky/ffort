program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer(4)::s
allocate(b(4))
b=9
allocate(a(1),b(2),c(3),stat=s)
print *,s>0,allocated(a),allocated(b),allocated(c),size(b),sum(b)
end program
