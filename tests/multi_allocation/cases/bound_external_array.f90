program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer::s
integer::other(2)=[2,3]
allocate(a(other(1)),b(size(other)),c(sum(other)),stat=s)
print *,s,size(a),size(b),size(c)
end program
