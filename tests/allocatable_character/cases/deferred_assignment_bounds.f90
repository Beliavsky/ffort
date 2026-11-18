program p
character(:),allocatable::a(:),b(:)
allocate(character(2)::a(-1:0))
allocate(character(4)::b(5:6))
a='xx'; b='test'
a=b
print *,len(a),lbound(a,1),ubound(a,1)
a='z'
print *,len(a),lbound(a,1),ubound(a,1)
end program
