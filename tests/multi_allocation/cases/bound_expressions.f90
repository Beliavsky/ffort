program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer::s
integer,parameter::n=3
integer::m=2
allocate(a(n+m),b(-m:n),c(max(n,m)),stat=s)
print *,s,size(a),size(b),size(c),lbound(b,1)
end program
