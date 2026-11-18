program p
implicit none
integer,allocatable::a(:)
allocate(a(3))
a=[0,1,32]
print *,maskr(a,4)
deallocate(a)
end program
