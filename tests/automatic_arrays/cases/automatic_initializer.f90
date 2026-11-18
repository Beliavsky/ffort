module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer::aa(n)=1
print *,aa
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(3)
end program
