module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer::aa(n)
aa=1
aa(2:n)=3
print *,sum(aa)
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(4)
call work(1)
call work(0)
end program
