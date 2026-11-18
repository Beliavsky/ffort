program p
implicit none
integer::i
real::a(-2:0)
print '(3i4)',lbound(a,kind=8),ubound(a),kind(lbound(a,kind=8))
print '(3i4)',[(i,i=lbound(a,1),ubound(a,1))]
end program
