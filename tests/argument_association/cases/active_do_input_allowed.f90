program main

implicit none
integer :: i
do i=1,3
call change(i)
end do
contains
subroutine change(x)
integer, intent(in) :: x
print *,x
end subroutine change
end program main
