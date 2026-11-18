program p
implicit none
integer::a(3,3)
a=reshape([1,2,3,4,5,6,7,8,9],[3,3])
a=cshift(a,a(:,1),2)
if(any(a/=reshape([4,8,3,7,2,6,1,5,9],[3,3]))) error stop 1
print *, "PASS"
end program
