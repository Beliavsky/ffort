program p
implicit none
integer(8),allocatable::a(:,:,:)
allocate(a(2,1,2))
a=1_8
print *,leadz(a)
print *,shape(leadz(a))
end program
