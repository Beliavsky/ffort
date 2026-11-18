program p
implicit none
integer,allocatable::a(:,:),s(:),b(:,:)
integer::n
n=2
allocate(a(2,3))
allocate(s(n))
a=1
s=0
b=cshift(a,s)
print *, "PASS"
end program
