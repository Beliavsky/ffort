program p
implicit none
integer(8)::x
integer::pos
character(:),allocatable::s,c(:)
s='M'
c=[s]
print '(a,3i3)',c,kind(not(x)),kind(btest(x,pos)),bit_size(x)
end program
