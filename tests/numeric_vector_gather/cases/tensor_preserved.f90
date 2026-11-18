program p
implicit none
integer::a(2,2,2),b(2,2,2)
a=1
a(2,1,1)=7
b=a([2,1],:,:)
if(b(1,1,1)/=7.or.b(2,1,1)/=1)error stop 1
print '(i0)',1
end program
