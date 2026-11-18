module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer::aa(n),bb(n,0),cc(0,n)
aa=1
bb=2
cc=3
print *,size(aa),size(bb),size(cc),sum(aa),sum(bb),sum(cc)
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(-5)
end program
