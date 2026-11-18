module automatic_fixture
implicit none
contains
subroutine work(n)
integer,optional,intent(in)::n
integer::aa(n)
aa=1
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(3)
end program
