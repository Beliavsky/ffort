module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer::aa(n,n)
print *,123
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(50000)
end program
