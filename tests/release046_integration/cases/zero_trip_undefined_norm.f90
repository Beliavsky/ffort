program p
implicit none
integer::i
real::v(2)
real,allocatable::a(:)
a=[(norm2(v),i=1,0)]
print '(3i3)',size(a),lbound(a),ubound(a)
end program
