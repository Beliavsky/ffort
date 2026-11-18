program p
implicit none
integer::a(3,3)
a=reshape([1,2,3,4,5,6,7,8,9],[3,3])
a=cshift(a,[1,-1,2],1)
if(any(a/=reshape([2,3,1,6,4,5,9,7,8],[3,3]))) error stop 1
a(:,3:1:-1)=cshift(a(:,3:1:-1),1,2)
if(any(a/=reshape([9,7,8,2,3,1,6,4,5],[3,3]))) error stop 2
print *, "PASS"
end program
