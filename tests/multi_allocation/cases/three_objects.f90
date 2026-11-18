program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer::s
allocate(a(2),b(-1:1),c(0),stat=s)
a=3
b=4
print *,s,size(a),size(b),size(c),sum(a),sum(b)
deallocate(a,b,c,stat=s)
print *,s,allocated(a),allocated(b),allocated(c)
end program
