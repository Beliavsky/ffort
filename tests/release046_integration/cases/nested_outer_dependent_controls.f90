program p
implicit none
integer::i,j,a(6)
i=77
j=88
a=[((10*i+j,j=1,i),i=1,3)]
print '(10i4)',lbound(a,kind=8),ubound(a,kind=8),a,i,j
end program
