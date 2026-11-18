program main
implicit none
character(:),allocatable::a(:)
call work(a)
contains
subroutine work(x)
character(:),allocatable,intent(in)::x(:)
character(len=len(x(1)))::y
y='test'
end subroutine
end program
