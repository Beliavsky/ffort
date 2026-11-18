module automatic_fixture
implicit none
contains
subroutine work(n,xx)
integer,intent(in)::n,xx(:,:)
integer::aa(size(xx,n))
print *,123
end subroutine

end module
program demo
use automatic_fixture
implicit none
integer::xx(2,2)
xx=1
call work(3,xx)
end program
