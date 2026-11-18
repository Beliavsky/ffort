program p
implicit none
integer::a(3,3,3),before(3,3,3),idx(3),i
a=reshape([(i,i=1,27)],[3,3,3])
before=a
idx=[3,1,1]
a=a(:,:,idx)
if(any(a/=before(:,:,idx)))error stop 1
print '(i0)',1
end program
