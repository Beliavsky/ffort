module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer::aa(n)
if (n==2) aa=1
if (n==1) print *,aa(1)
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(2)
call work(1)
end program
