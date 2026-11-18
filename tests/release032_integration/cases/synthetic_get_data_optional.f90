! Synthetic release 0.32 composition fixture; no original utility body.
module views
implicit none
contains
subroutine get_data(xx,yy)
real(8),intent(in),target::xx(:,:)
real(8),pointer,intent(out),optional::yy(:)
if(present(yy)) yy=>xx(:,2)
end subroutine
end module
program main
use views
implicit none
real(8),target::a(3,2)
real(8),pointer::p(:)
a=reshape([1.0_8,2.0_8,3.0_8,4.0_8,5.0_8,6.0_8],[3,2])
call get_data(a,p)
where(p>4.0_8) p=p*2.0_8
call get_data(a)
a(1,2)=8.0_8
print *,p,a(:,1),shape(p),findloc(p,10.0_8),associated(p)
end program
