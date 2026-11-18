program p
implicit none
integer::a(2,2),b(2,2)
a(:,1)=[1,2]
a(:,2)=[3,4]
b=a([2,1],:)
if(any(b(:,1)/=[2,1]).or.any(b(:,2)/=[4,3]))error stop 1
print '(i0)',1
end program
