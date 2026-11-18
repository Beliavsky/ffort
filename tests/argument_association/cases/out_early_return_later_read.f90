program main

implicit none
integer :: a
a=7
call change(a,.true.)
print *,a
contains
subroutine change(x,condition)
integer, intent(out) :: x
logical, intent(in) :: condition
if(condition) return
x=5
end subroutine change
end program main
