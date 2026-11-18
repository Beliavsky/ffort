module automatic_fixture
implicit none
contains
subroutine work(n)
integer,intent(out)::n
integer::aa(n)
n=3
end subroutine

end module
program demo
use automatic_fixture
implicit none
integer::n
call work(n)
end program
