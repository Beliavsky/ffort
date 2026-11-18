program p
implicit none
integer::a(4),idx(4),b(2)
a=[10,20,30,40]
idx=[4,1,3,2]
b=a(idx(4:2:-2))
if(any(b/=[20,10]))error stop 1
print '(i0)',1
end program
