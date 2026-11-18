module automatic_fixture
implicit none
contains
subroutine work(n)
real,intent(in)::n
integer::aa(n)
aa=1
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(3.0)
end program
