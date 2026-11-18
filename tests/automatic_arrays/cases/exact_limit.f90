module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer::aa(n)
aa=1
print *,size(aa),sum(aa)
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(131072)
end program
