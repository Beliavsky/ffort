program p
implicit none
integer::a(2,3),v(4),b(2,2)
a=reshape([1,2,3,4,5,6],[2,3])
v=pack(a,mod(a,2)==0,vector=[90,91,92,93])
b=reshape(shape=[2,2],source=v,order=[2,1])
print *,v,b
print *,pack(reshape([1,2,3,4,5,6],[2,3],order=[2,1]), &
reshape([1,2,3,4,5,6],[2,3],order=[2,1])>3)
print *,reshape(pack(a,.true.),[3,2],order=[2,1])
end program
