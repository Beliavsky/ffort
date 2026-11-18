program combined
implicit none
integer,allocatable::a(:),b(:)
allocate(a(-2:-3))
b=a
print '(a,3i4)', 'empty',b
b=[7,9]
print '(i4)',b
b=b(2:1)
print '(a,2i4)', 'empty again',b
print '(l2,2i4)',allocated(b),lbound(b,1),ubound(b,1)
end program
