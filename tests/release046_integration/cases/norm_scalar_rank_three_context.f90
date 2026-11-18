program p
implicit none
integer::i
real(8)::a(2,1,2),b(2,1,2)
a=reshape([(real(i,8),i=1,4)],[2,1,2])
b=norm2([3d0,4d0])+a+norm2([0d0,-0d0])
print '(4f5.1)',b
print '(6i3)',lbound(b),ubound(b)
end program
