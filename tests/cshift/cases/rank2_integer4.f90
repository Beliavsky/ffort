program p
implicit none
integer::a(3,4),b(3,4)
a=reshape([1,2,3,4,5,6,7,8,9,10,11,12],[3,4])
b=cshift(a,[1,-1,8,-7])
if(any(b/=reshape([2,3,1,6,4,5,9,7,8,12,10,11],[3,4]))) error stop 1
if(kind(b)/=kind(a)) error stop 2
if(any(shape(b)/=shape(a))) error stop 3
print *, "PASS"
end program
