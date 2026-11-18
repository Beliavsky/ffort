module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer::aa(n,0)
aa=1
print *,size(aa),size(aa,1),size(aa,2)
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(2147483647)
end program
