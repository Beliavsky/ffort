program p
integer,allocatable::a(:,:,:)
integer::k
allocate(a(2,2,-1:0)); a=7
k=1
print *,a(1,1,k)
end program
