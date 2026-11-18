program p
implicit none
integer(8),allocatable::a(:,:,:)
allocate(a(2,1,2))
a=1_8
print *,sum(leadz(a)),shape(leadz(a))
end program
