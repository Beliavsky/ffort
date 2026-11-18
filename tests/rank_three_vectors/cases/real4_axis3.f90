program p
implicit none
real(4)::a(3,3,3),b(3,3,2)
integer::i,idx(2)
a=reshape([(i,i=1,27)],[3,3,3])
idx=[3,1]
b=a(:,:,idx)
if(any(b/=reshape([19,20,21,22,23,24,25,26,27,1,2,3,4,5,6,7,8,9],[3,3,2])))error stop 1
print '(i0)',1
end program
