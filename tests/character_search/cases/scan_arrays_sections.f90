program p
implicit none
character(3)::a(3),z(0)
logical::back(3)
a=['aba','bba','ccc']
back=[.false.,.true.,.false.]
print *, scan(a,'a'), scan(a,'a',back)
print *, scan(a(3:1:-1),'a',.true.)
print *, scan('aba',['a','b','c'],back)
print *, scan(reshape(a(:2),[1,2]),'a',kind=8)
print *, size(scan(z,'a')), sum(scan(z,'a')), kind(scan(z,'a',kind=8))
end program
