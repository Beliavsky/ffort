program p
implicit none
integer(8)::x
character(:),allocatable::s,c(:)
s='M'
c=[s]
print '(a,3i3)',c,kind(not(x)),kind(btest(x,999)),bit_size(x)
end program
