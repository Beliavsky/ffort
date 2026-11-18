module automatic_fixture
implicit none
contains
subroutine work(n)
integer(kind=8),intent(in)::n
integer::aa(n)
print *,123
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(2147483648_8)
end program
