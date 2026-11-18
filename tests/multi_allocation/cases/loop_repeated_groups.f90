program p
implicit none
integer,allocatable::a(:),b(:),c(:)
integer::s
integer::j
do j=1,3
allocate(a(j),b(j+1),c(0),stat=s)
a=j
b=j
print *,s,sum(a),sum(b)
deallocate(a,b,c,stat=s)
if(s/=0) error stop 1
end do
end program
