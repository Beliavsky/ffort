module automatic_fixture
implicit none
contains
subroutine work(n)
integer,intent(inout)::n
integer :: aa(-2:n-3), bb(n+1)
aa=2
bb=3
n=n+4
print *, size(aa),lbound(aa,1),ubound(aa,1),sum(aa),sum(bb)
end subroutine

end module
program demo
use automatic_fixture
implicit none
integer :: n
n=3
call work(n)
print *,n
n=0
call work(n)
end program
