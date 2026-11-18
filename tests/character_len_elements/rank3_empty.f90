program main
implicit none
character(7)::a(0,2,2)
call work(a)
print *, 'PASS'
contains
subroutine work(x)
character(*),intent(in)::x(:,:,:)
character(len=len(x(1,1,1)))::y(0)
if(len(y)/=7.or.size(y)/=0) error stop 1
end subroutine
end program
