program p
logical,allocatable::a(:,:,:)
allocate(a(2,1,2));a(1,1,1)=.true.
print *,a(2,1,2)
end program
