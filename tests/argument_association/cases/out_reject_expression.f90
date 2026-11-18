program main

implicit none
integer :: a
print *,123
call change(a+1)
contains
subroutine change(x)
integer, intent(out) :: x
x=1
end subroutine change

end program main
