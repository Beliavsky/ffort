program p
implicit none
real::a(-1:-2,4:6)
print '(4i3,f4.1)',lbound(a),ubound(a),norm2(a)
end program
