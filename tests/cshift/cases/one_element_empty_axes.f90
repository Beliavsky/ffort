program p
implicit none
integer::a(0,3),b(3,0),c(0),s(0),one(1,1)
a=0
b=0
c=0
s=0
one=17
if(any(cshift(one,-9223372036854775807_8-1_8)/=one)) error stop 1
if(size(cshift(c,9))/=0) error stop 2
if(size(cshift(a,[1,-1,0],1))/=0) error stop 3
if(size(cshift(a,s,2))/=0) error stop 4
if(size(cshift(b,s,1))/=0) error stop 5
if(size(cshift(b,[1,2,3],2))/=0) error stop 6
print *, "PASS"
end program
