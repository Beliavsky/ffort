module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer::aa(1/n)
print *,123
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(0)
end program
