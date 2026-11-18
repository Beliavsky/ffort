program main

implicit none
integer :: a
a=4
call change((a),a)
print *,a
contains
subroutine change(x,y)
integer, intent(in) :: x
integer, intent(out) :: y
y=x+2
end subroutine change
end program main
