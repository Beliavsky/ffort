program p
implicit none
integer,allocatable::a(:),b(:)
allocate(a(2));allocate(b(3));a=1;b=2
print *,dim(a,b)
end program
