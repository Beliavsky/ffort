module automatic_fixture
implicit none
contains
subroutine work(nn)
integer,intent(in)::nn(:)
integer::aa(nn(1))
aa=1
end subroutine

end module
program demo
use automatic_fixture
implicit none
call work([3])
end program
