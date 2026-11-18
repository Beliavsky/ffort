program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer(4)::s
allocate(a(4))
a=9
allocate(a(1),b(2),c(3),stat=s)
print *,s>0,allocated(a),allocated(b),allocated(c),size(a),sum(a)
end program
