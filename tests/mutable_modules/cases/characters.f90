module state
implicit none
character(4)::counter(2)=['one ','two ']
contains
subroutine change()
counter(2)='next'
end subroutine
end module
program main
use state
implicit none
call change()
print '(a,1x,a)',counter(1),counter(2)
end program
