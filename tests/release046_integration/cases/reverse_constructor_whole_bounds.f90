program p
implicit none
integer::i,a(-2:0)
i=77
a=[(i,i=3,1,-1)]
print '(6i4)',lbound(a),ubound(a),a,i
end program
