module automatic_fixture
implicit none
contains
subroutine work(xx)
real,intent(in)::xx(:,:)
real :: aa(size(xx,1),size(xx,2)), bb(0:size(xx,2)-1,-1:size(xx,1)-2)
aa=xx
bb=2.0
print *,size(aa,1),size(aa,2),sum(aa),sum(bb),lbound(bb,1),lbound(bb,2)
end subroutine

end module
program demo
use automatic_fixture
implicit none
real :: data(2,3)
data=3.0
call work(data)
call work(data(:,2:1))
call work(data(2:1,:))
end program
