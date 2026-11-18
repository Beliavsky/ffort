program p
implicit none
real(4)::a(3,3,3),b(2,3,3)
integer::i,idx(2)
a=reshape([(i,i=1,27)],[3,3,3])
idx=[3,1]
b=a(idx,:,:)
if(any(b/=reshape([3,1,6,4,9,7,12,10,15,13,18,16,21,19,24,22,27,25],[2,3,3])))error stop 1
print '(i0)',1
end program
