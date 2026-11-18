program p
implicit none
integer(4),allocatable::a(:,:,:)
allocate(a(2,1,2))
a=1_4
print *,sum(leadz(a)),shape(leadz(a))
end program
