module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
integer::aa(3),bb(size(aa))
aa=1
bb=2
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(3)
end program
