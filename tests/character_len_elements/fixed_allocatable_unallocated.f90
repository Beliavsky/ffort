program main
implicit none
character(4),allocatable::a(:)
call work(a)
print *, 'PASS'
contains
subroutine work(x)
character(*),allocatable,intent(in)::x(:)
character(len=len(x(1)))::y
y='test'
if(y/='test') error stop 1
end subroutine
end program
