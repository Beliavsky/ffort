module m
implicit none

contains
subroutine report()
print *,7
end subroutine report
end module m
program main
use m
implicit none

call report()
end program main
