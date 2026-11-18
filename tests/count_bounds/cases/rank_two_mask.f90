module m
implicit none
contains
subroutine work(x)
integer,intent(in)::x(:,:)

integer::a(count(x>0),2)

a=7
print *,size(a,1),size(a,2),sum(a)
end subroutine
end module
program p
use m
implicit none
integer::v(-1:0,3)
v(:,1)=[-1,2]
v(:,2)=[3,0]
v(:,3)=[5,-6]
call work(v)
end program
