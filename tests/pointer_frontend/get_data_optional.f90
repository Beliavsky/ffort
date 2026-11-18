module m
contains
subroutine get_data(xx,yy)
real(8),intent(in),target::xx(:,:)
real(8),pointer,intent(out),optional::yy(:)
if(present(yy)) yy=>xx(:,2)
end subroutine
end module
program main
use m
real(8),target::a(2,2)
real(8),pointer::p(:)
a=0.0_8
a(:,2)=[3.0_8,4.0_8]
call get_data(a,p)
if(p(2)/=4.0_8) error stop 1
p(1)=9.0_8
if(a(1,2)/=9.0_8) error stop 2
a(2,2)=8.0_8
if(p(2)/=8.0_8) error stop 3
call get_data(a)
end
