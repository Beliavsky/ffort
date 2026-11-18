program p
implicit none
integer(8)::a(3,4),b(3,4)
a=reshape([1_8,2_8,3_8,4_8,5_8,6_8,7_8,8_8,9_8,10_8,11_8,12_8],[3,4])
b=cshift(a,[1,-1,8,-7])
if(any(b/=reshape([2_8,3_8,1_8,6_8,4_8,5_8,9_8,7_8,8_8,12_8,10_8,11_8],[3,4]))) error stop 1
if(kind(b)/=kind(a)) error stop 2
if(any(shape(b)/=shape(a))) error stop 3
print *, "PASS"
end program
