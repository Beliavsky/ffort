module elemental_fixture
implicit none
contains
elemental integer function total(n) result(answer)
integer,intent(in)::n
integer::aa(n)
aa=2
answer=sum(aa)
end function
end module
program demo
use elemental_fixture
implicit none
print *,total([3,0,-1,2])
end program
