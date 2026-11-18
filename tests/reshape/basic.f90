program p
implicit none
integer::a(2,3),b(3,2),v(6),sh(2),ord(2),empty(0),z(0,3)
integer(8)::wide(2)
real(8)::r(2,2)
logical::l(2,2)
character(2)::c(2,2)
a=reshape([1,2,3,4,5,6],[2,3])
b=reshape(a,[3,2])
v=reshape(a,[size(a)])
print *,a,b,v
sh=[3,2];ord=[2,1]
b=reshape(order=ord,shape=sh,source=v)
print *,b
b=reshape([1,2],sh,pad=[9,8],order=ord)
print *,b
print *,reshape(source=empty,shape=[5],pad=[7,8])
print *,reshape(a(:,3:1:-1),[6])
print *,reshape([1,2,3],[2])
wide=[9007199254740993_8,-2147483649_8]
print *,reshape(wide,[2,2],pad=wide)
r=reshape([1.5d0,2.5d0],[2,2],pad=[3.5d0])
l=reshape([.true.,.false.],[2,2],pad=[.false.,.true.],order=[2,1])
c=reshape(['ab','cd'],[2,2],pad=['ef'])
print *,r,l
print *,c(1,1),' ',c(2,1),' ',c(1,2),' ',c(2,2)
z=reshape(empty,[0,3],pad=empty,order=[2,1])
print *,size(z),size(reshape(a,[2,0])),sum(reshape(a,[0]))
print *,kind(reshape(wide,[2,2],pad=wide))
end program
