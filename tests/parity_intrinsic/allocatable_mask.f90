program p
implicit none
logical,allocatable::a(:,:)
allocate(a(2,3))
a=.true.
print *,parity(a,dim=2)
deallocate(a)
end program
