program main

implicit none
integer :: a(5)
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(out) :: x(-2:)
integer :: i
do i=lbound(x,1),ubound(x,1)
x(i)=i
end do
end subroutine change
end program main
