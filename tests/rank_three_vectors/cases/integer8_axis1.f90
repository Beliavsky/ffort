program p
implicit none
integer(8)::a(3,3,3),b(2,3,3)
integer::i,idx(2)
a=reshape([(i,i=1,27)],[3,3,3])
idx=[3,1]
b=a(idx,:,:)
if(any(b/=reshape([3_8,1_8,6_8,4_8,9_8,7_8,12_8,10_8,15_8,13_8,18_8,16_8,21_8,19_8,24_8,22_8,27_8,25_8],[2,3,3])))error stop 1
print '(i0)',1
end program
