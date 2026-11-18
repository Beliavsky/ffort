program p
logical,allocatable::a(:,:,:)
integer::k
allocate(a(2,1,7:8));a=.true.;k=9
print *,a(1,1,k)
end program
