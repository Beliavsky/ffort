program p
implicit none
integer::u
character(:),allocatable::a(:,:),b
integer::s
u=27
allocate(character(3)::a(2,2))
allocate(character(2)::b)
read(u,*,iostat=s)a,b
if(s/=0.or.len(a)/=3.or.len(b)/=2)stop 1
print "(a)",a,b
end program
