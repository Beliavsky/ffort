program p
implicit none
integer::a(2,3),s(-2:3)
a=reshape([1,2,3,4,5,6],[2,3])
s=[1,99,-2,99,3,99]
if(any(cshift(a,s(-2:2:2),1)/=reshape([2,1,3,4,6,5],[2,3]))) error stop 1
print *, "PASS"
end program
