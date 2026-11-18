module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer,parameter::k=2
integer::aa(k,n),bb(n,int(2.9))
aa=2
bb=3
print *,size(aa,1),size(aa,2),sum(aa),sum(bb)
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(3)
end program
