program main

implicit none

call label('first')
call label('second')
contains
subroutine label(s)
character(len=*), intent(in) :: s
print '(a)',s
end subroutine label
end program main
