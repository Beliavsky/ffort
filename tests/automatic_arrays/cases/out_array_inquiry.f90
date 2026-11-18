module automatic_fixture
implicit none
contains
subroutine work(xx)
real,intent(out)::xx(:)
integer :: aa(size(xx))
aa=7
xx=real(aa)
print *,sum(aa)
end subroutine

end module
program demo
use automatic_fixture
implicit none
real :: data(3)
call work(data)
print *,data
end program
