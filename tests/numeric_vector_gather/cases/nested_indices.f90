program p
implicit none
integer::a(4),map(4),idx(3),b(3)
a=[10,20,30,40]
map=[4,1,3,2]
idx=[2,1,2]
b=a(map(idx))
if(any(b/=[10,40,10]))error stop 1
print '(i0)',1
end program
