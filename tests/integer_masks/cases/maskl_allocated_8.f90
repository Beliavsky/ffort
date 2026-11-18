program p
implicit none
integer,allocatable::a(:)
allocate(a(3))
a=[0,1,64]
print *,maskl(a,8)
deallocate(a)
end program
