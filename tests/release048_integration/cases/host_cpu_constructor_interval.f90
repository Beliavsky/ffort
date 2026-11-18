program p
implicit none
real(8)::a,b
integer::i,n
character(:),allocatable::s,c(:)
call cpu_time(a)
n=0
do i=0,31
 n=ieor(n,i)
end do
s='CPU '
c=[s,s]
call cpu_time(time=b)
if(.not.(abs(a)<=huge(a)).or..not.(abs(b)<=huge(b)))stop 1
if(a>=0.and.b>=0.and.b<a)stop 2
print '(*(a))',c
print '(z8.8)',n
end program
