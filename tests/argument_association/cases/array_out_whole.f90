program main

implicit none
integer :: a(-2:2)
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(out) :: x(:)
integer :: i
do i=1,size(x)
x(i)=i*2
end do
end subroutine change
end program main
