program p
implicit none
integer::i(4)=[-2,0,1,16777217]
real(4)::a(4)
real(8)::b(4)
a=real(i)
b=real(i,8)
print *,kind(real(i)),size(real(i)),a,b
print *,kind(real(i,8)),sum(real(i,8))
print *,real([1,2,3],kind=8)
print *,real(kind=4,a=b)==a
end program p
