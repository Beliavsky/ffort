program main

implicit none
integer :: a
a=1
print *,inspect(a)
contains
integer function inspect(x) result(r)
integer, intent(inout) :: x
x=x+1
r=x
end function inspect
end program main
