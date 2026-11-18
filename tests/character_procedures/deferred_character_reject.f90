module m
implicit none
contains
subroutine work()
character(:),allocatable::a(:)
end subroutine
end module m
program test
use m
implicit none


end program test
