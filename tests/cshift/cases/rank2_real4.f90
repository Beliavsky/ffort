program p
implicit none
real::a(3,4),b(3,4)
a=reshape([1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0,11.0,12.0],[3,4])
b=cshift(a,[1,-1,8,-7])
if(any(b/=reshape([2.0,3.0,1.0,6.0,4.0,5.0,9.0,7.0,8.0,12.0,10.0,11.0],[3,4]))) error stop 1
if(kind(b)/=kind(a)) error stop 2
if(any(shape(b)/=shape(a))) error stop 3
print *, "PASS"
end program
