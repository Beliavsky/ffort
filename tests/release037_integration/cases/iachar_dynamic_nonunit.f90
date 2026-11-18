module strings
implicit none
contains
subroutine code(c)
character(*),intent(in)::c
write(*,'(a)')'before'
print *,7,iachar(c)
end subroutine
end module
program main
use strings
call code('AB')
end program
