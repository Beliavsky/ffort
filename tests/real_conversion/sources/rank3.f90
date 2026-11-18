program p
implicit none
integer::i(2,2,2)
real(4)::a(2,2,2)
real(8)::b(2,2,2)
i(:,:,1)=reshape([1,2,3,4],[2,2])
i(:,:,2)=reshape([5,6,7,8],[2,2])
a=real(i)
b=real(i,8)
print *,shape(real(i,8)),kind(real(i,8)),sum(a(:,:,1)),sum(b(:,:,2))
print *,b(:,:,1),b(:,:,2)
print *,real(b(2,2,2),4)==a(2,2,2)
end program p
