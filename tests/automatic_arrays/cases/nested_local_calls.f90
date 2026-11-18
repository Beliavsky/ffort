module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer::aa(n)
aa=1
call inner(n+1)
print *,size(aa),sum(aa)
end subroutine
subroutine inner(n)
integer,intent(in)::n
integer::bb(n)
bb=2
print *,size(bb),sum(bb)
end subroutine
end module
program demo
use automatic_fixture
implicit none
call work(3)
end program
