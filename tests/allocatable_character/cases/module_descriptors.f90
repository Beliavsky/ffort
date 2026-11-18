module m
implicit none
character(:),allocatable::saved(:)
contains
subroutine build()
allocate(character(4)::saved(-2:-1));saved='abc'
end subroutine
subroutine change()
saved=['x','y','z']
end subroutine
end module
program main
use m
implicit none
call build()
print *,len(saved),lbound(saved,1)
call change()
print *,len(saved),size(saved),lbound(saved,1)
print '(3a2)',saved
end program
