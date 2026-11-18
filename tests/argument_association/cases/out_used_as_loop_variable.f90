program main

implicit none
integer :: a
call change(a)
print *,a
contains
subroutine change(x)
integer, intent(out) :: x
do x=1,3
end do
end subroutine change
end program main
