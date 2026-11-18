program p
implicit none
integer(8)::x
character(:),allocatable::s,c(:)
x=-huge(0_8)
x=x-1_8
s='['
c=[s]
print '(a,z0.0,a)',c,ior(x,0_8),']'
end program
