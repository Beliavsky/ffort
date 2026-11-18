program p
implicit none
integer::a(4),b(4),i
a=[1,2,3,4]
b=0
where(a>1) b=cshift(a,1)
if(any(b/=[0,3,4,1])) error stop 1
forall(i=1:4) b(i)=sum(cshift(a,i))
if(any(b/=10)) error stop 2
print *, "PASS"
end program
