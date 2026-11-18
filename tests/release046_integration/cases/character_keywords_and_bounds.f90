program p
implicit none
character(3)::a(2),b(2)
integer(8)::bounds(2)
a=['aaa','zzz']
b=max(a3='mmm',a1=a,a2='bb')
bounds=[lbound(b,kind=8),ubound(b,kind=8)]
print '(2i3,a,a,a,a,a)',bounds,'[',b(1),'][',b(2),']'
end program
