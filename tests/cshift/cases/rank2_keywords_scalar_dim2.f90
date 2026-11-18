program p
implicit none
integer::a(3,4),b(3,4)
a=reshape([1,2,3,4,5,6,7,8,9,10,11,12],[3,4])
b=cshift(dim=2_8,shift=-1_8,array=a)
if(any(b/=reshape([10,11,12,1,2,3,4,5,6,7,8,9],[3,4]))) error stop 1
print *, "PASS"
end program
