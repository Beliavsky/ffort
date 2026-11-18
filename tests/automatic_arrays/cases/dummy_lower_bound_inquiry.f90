module automatic_fixture
implicit none
contains
subroutine work(xx)
integer,intent(in)::xx(-3:)
integer::aa(lbound(xx,1):ubound(xx,1))
aa=2
print *,size(aa),lbound(aa,1),ubound(aa,1),sum(aa)
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work([1,2,3,4])
end program
