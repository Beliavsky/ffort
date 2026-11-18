program p
implicit none
integer::u
integer,allocatable::a(:,:)
real(8),allocatable::b(:,:)
integer::s
u=27
allocate(a(2,2),b(2,2))
read(u,*,iostat=s)a,b
if(s/=0)stop 1
print *,a,b
end program
