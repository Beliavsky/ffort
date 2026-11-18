module values
implicit none
integer :: x=1
end module values
program probe
use values
implicit none
print *, x
end program probe
