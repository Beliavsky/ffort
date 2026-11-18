program main

implicit none
integer :: a(5)
a=0
call change(a(5:1:-2))
print *,a
contains
subroutine change(x)
integer, intent(out) :: x(:)
integer :: i
do i=1,size(x)
x(i)=i
end do
end subroutine change
end program main
