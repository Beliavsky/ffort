program p
implicit none
integer(8)::a(3,3,3),b(3,3,2)
integer::i,idx(2)
a=reshape([(i,i=1,27)],[3,3,3])
idx=[3,1]
b=a(:,:,idx)
if(any(b/=reshape([19_8,20_8,21_8,22_8,23_8,24_8,25_8,26_8,27_8,1_8,2_8,3_8,4_8,5_8,6_8,7_8,8_8,9_8],[3,3,2])))error stop 1
print '(i0)',1
end program
