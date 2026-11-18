program p
implicit none
integer::i
real::a(-1:0,4:6)
real,allocatable::b(:,:)
a=reshape([(real(i),i=1,6)],[2,3])
b=transpose(a)+norm2([3.,4.])
print '(4i3)',lbound(b),ubound(b)
print '(6f5.1)',b
end program
