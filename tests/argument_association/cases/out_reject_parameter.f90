program main

implicit none
integer, parameter :: a=2
print *,123
call change(a)
contains
subroutine change(x)
integer, intent(out) :: x
x=1
end subroutine change

end program main
