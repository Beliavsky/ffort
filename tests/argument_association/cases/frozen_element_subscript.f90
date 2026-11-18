program main

implicit none
integer :: a(4),i
a=0
i=2
call change(a(i),i)
print *,a,i
contains
subroutine change(x,j)
integer, intent(out) :: x,j
j=4
x=7
end subroutine change
end program main
