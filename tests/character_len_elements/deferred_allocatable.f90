program main
implicit none
character(:),allocatable::a(:)
allocate(character(5)::a(0))
call work(a)
print *, 'PASS'
contains
subroutine work(x)
character(:),allocatable,intent(in)::x(:)
character(len=len(x(1)))::y
y='test'
if(len(y)/=5.or.y/='test ') error stop 1
end subroutine
end program
