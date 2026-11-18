program p
implicit none
integer::undefined
character(:),allocatable::s,a(:)
s=repeat('x',bit_size(undefined)/8)
a=[s,s]
print '(2i3)',len(a),bit_size(undefined)
print '(*(a))','[',a,']'
end program
