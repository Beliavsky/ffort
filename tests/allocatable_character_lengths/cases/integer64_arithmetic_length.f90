program p
implicit none
integer(8) :: n
character(5),allocatable :: x(:)
n=3_8
call fill(n,x)
if (len(x)/=5 .or. size(x)/=1 .or. x(1)/='abcde') error stop 1
print *,1
contains
subroutine fill(n,a)
integer(8),intent(in) :: n
character(len=max(0_8,n*2_8-1_8)),allocatable,intent(out) :: a(:)
allocate(a(1))
a='abcdef'
end subroutine
end program
