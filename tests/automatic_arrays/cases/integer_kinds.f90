module automatic_fixture
implicit none
contains
subroutine work(n)
integer(kind=8),intent(in)::n
integer(kind=8) :: aa(n)
real(kind=8) :: bb(n)
logical :: cc(n)
aa=4_8
bb=2.5_8
cc=.true.
print *,sum(aa),sum(bb),all(cc)
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(4_8)
end program
