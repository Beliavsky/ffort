program p
implicit none
integer,allocatable::a(:,:)
allocate(a(-2:1,3:5))
print *,shape(a)
deallocate(a)
allocate(a(0,2))
print *,shape(a)
end program
