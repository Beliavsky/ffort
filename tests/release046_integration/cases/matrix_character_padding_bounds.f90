program p
implicit none
character(3)::a(-1:0,2:3),b(2,2)
a=reshape(['a  ','z  ','b  ','y  '],[2,2])
b=max(a,'m')
print '(4i4)',lbound(a,kind=8),ubound(a,kind=8)
print '(*(a))','[',b(1,1),'][',b(2,1),'][',b(1,2),'][',b(2,2),']'
end program
