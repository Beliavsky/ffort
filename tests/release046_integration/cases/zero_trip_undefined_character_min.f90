program p
implicit none
integer::i
character(3)::x
character(3),allocatable::a(:)
a=[(min(x,'b'),i=1,0)]
print '(3i3)',size(a),lbound(a),ubound(a)
end program
