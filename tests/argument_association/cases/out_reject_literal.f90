program main

implicit none

print *,123
call change(3)
contains
subroutine change(x)
integer, intent(out) :: x
x=1
end subroutine change

end program main
