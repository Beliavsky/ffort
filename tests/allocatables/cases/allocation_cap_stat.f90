program main
implicit none
integer,allocatable::a(:),b(:)
integer::s
allocate(a(1000000))
allocate(b(1),stat=s)
print *,s/=0,allocated(b)
deallocate(a)
allocate(b(1000000),stat=s)
print *,s,size(b)
end program
