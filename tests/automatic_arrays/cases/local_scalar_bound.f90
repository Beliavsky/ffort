module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer::k,aa(k)
k=n
aa=1
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(3)
end program
