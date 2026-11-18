program p
implicit none
integer::i(0),j(0,2),k(2,0,2)
real(8)::a(0),b(0,2),c(2,0,2)
a=real(i,8)
b=real(j,8)
c=real(k,8)
print *,size(real(i,8)),size(real(j,8)),size(real(k,8))
print *,shape(b),shape(c),sum(a),sum(b),size(c)
print *,kind(real(i)),kind(real(j,8)),kind(real(k,8))
end program p
