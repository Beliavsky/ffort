module m
implicit none

contains
subroutine report(x)
integer, intent(in) :: x
if(x<0) then
print *,1
return
end if
print *,2
end subroutine report
end module m
program main
use m
implicit none

call report(-1)
call report(0)
end program main
