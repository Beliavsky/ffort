program p
implicit none
character(3)::a(3),z(0)
logical::back(3)
a=['aba','bba','ccc']
back=[.false.,.true.,.false.]
print *, verify(a,'a'), verify(a,'a',back)
print *, verify(a(3:1:-1),'a',.true.)
print *, verify('aba',['a','b','c'],back)
print *, verify(reshape(a(:2),[1,2]),'a',kind=8)
print *, size(verify(z,'a')), sum(verify(z,'a')), kind(verify(z,'a',kind=8))
end program
