program p
implicit none
integer(4),allocatable::a(:,:,:)
allocate(a(2,1,2))
a=1_4
print *,leadz(a)
print *,shape(leadz(a))
end program
