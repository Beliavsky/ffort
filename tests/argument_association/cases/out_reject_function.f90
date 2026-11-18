program main

implicit none

print *,123
call change(inspect())
contains
subroutine change(x)
integer, intent(out) :: x
x=1
end subroutine change
integer function inspect() result(r)

r=3
end function inspect
end program main
