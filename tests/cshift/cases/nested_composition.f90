program p
implicit none
integer::a(2,3),b(2,3)
a=reshape([1,2,3,4,5,6],[2,3])
b=cshift(cshift(a,[1,0,-1]),[1,-1],2)
if(any(b/=reshape([3,5,6,1,2,4],[2,3]))) error stop 1
if(sum(cshift(a,1))/=21) error stop 2
if(any(shape(cshift(a,1))/=[2,3])) error stop 3
print *, "PASS"
end program
