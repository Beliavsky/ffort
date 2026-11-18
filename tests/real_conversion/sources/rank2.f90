program p
implicit none
integer::i(2,2)
real(4)::a(2,2)
real(8)::b(2,2)
i=reshape([1,2,3,16777217],[2,2])
a=real(i,4)
b=real(i,8)
print *,shape(real(i,8)),kind(real(i,8)),sum(b),sum(a)
print *,b(:,1),b(:,2)
print *,real(b,4)==a
end program p
