program p
implicit none
integer,allocatable::a(:,:),b(:,:),s(:)
integer::n,d
n=3
d=2
allocate(a(-1:1,4:7))
allocate(s(-2:0))
a=reshape([1,2,3,4,5,6,7,8,9,10,11,12],[3,4])
s=[1,-2,5]
b=cshift(a,s,d)
if(any(shape(b)/=[3,4])) error stop 1
if(any(b/=reshape([4,8,6,7,11,9,10,2,12,1,5,3],[3,4]))) error stop 2
if(lbound(b,1)/=1.or.lbound(b,2)/=1) error stop 3
print *, "PASS"
end program
