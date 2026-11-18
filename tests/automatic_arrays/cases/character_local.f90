module automatic_fixture
implicit none
contains
subroutine work(n)
integer, intent(in) :: n
character(len=3)::aa(n)
aa="cat"
print *,size(aa),aa
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work(3)
end program
