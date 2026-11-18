program p
implicit none
integer::x,a(0)
logical::b(0)
character(:),allocatable::s,c(:)
a=iand(a,x)
b=btest(a,x)
s=''
c=[s,s]
print '(3i2)',size(a),size(b),len(c)
print '(*(a))','[',c,']'
end program
