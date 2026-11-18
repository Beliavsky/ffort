module m
integer,allocatable::a(:)
end module
module n
integer,allocatable::b(:)
end module
program main
use m
use n
integer::s
allocate(a(500001))
allocate(b(500001),stat=s)
print *,s/=0,allocated(b),size(a)
end program
