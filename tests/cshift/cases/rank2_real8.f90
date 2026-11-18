program p
implicit none
real(8)::a(3,4),b(3,4)
a=reshape([1.0_8,2.0_8,3.0_8,4.0_8,5.0_8,6.0_8,7.0_8,8.0_8,9.0_8,10.0_8,11.0_8,12.0_8],[3,4])
b=cshift(a,[1,-1,8,-7])
if(any(b/=reshape([2.0_8,3.0_8,1.0_8,6.0_8,4.0_8,5.0_8,9.0_8,7.0_8,8.0_8,12.0_8,10.0_8,11.0_8],[3,4]))) error stop 1
if(kind(b)/=kind(a)) error stop 2
if(any(shape(b)/=shape(a))) error stop 3
print *, "PASS"
end program
