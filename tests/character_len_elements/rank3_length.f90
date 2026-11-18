program main
implicit none
character(5)::a(2,2,2)
a='abc'
call work(a)
print *, 'PASS'
contains
subroutine work(x)
character(*),intent(in)::x(:,:,:)
character(len=len(x(1,1,1)))::y(2)
y=x(1,1,1)
if(len(y)/=5.or.any(y/='abc  ')) error stop 1
end subroutine
end program
