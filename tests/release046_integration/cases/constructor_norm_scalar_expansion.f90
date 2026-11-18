program p
implicit none
integer::i
real::a(3)
i=99
a=[(real(i),i=1,3)]+norm2([3.,4.])
print '(3f4.1,i4)',a,i
end program
