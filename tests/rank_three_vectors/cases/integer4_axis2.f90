program p
implicit none
integer(4)::a(3,3,3),b(3,2,3)
integer::i,idx(2)
a=reshape([(i,i=1,27)],[3,3,3])
idx=[3,1]
b=a(:,idx,:)
if(any(b/=reshape([7,8,9,1,2,3,16,17,18,10,11,12,25,26,27,19,20,21],[3,2,3])))error stop 1
print '(i0)',1
end program
