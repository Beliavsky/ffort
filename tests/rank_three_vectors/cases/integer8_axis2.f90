program p
implicit none
integer(8)::a(3,3,3),b(3,2,3)
integer::i,idx(2)
a=reshape([(i,i=1,27)],[3,3,3])
idx=[3,1]
b=a(:,idx,:)
if(any(b/=reshape([7_8,8_8,9_8,1_8,2_8,3_8,16_8,17_8,18_8,10_8,11_8,12_8,25_8,26_8,27_8,19_8,20_8,21_8],[3,2,3])))error stop 1
print '(i0)',1
end program
