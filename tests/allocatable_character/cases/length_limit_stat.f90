program main
implicit none
character(:),allocatable::a(:)
integer::n,s
n=65537
allocate(character(n)::a(1),stat=s)
if(s==0.or.allocated(a)) error stop 1
print *,allocated(a)

end program
