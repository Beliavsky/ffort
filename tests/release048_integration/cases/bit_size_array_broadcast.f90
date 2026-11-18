program p
implicit none
integer::i
integer(8)::a(3),undefined(2)
character(:),allocatable::s,v(:)
a=[1_8,2_8,3_8]+bit_size(undefined)
s='K'
v=[s,s,s]
print '(*(a,z2.2))',(v(i),a(i),i=1,3)
end program
