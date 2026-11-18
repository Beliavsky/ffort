program p
implicit none
call q('fixed')
contains
subroutine q(msg)
character(*),intent(in) :: msg
integer,allocatable :: a(:)
allocate(a(1),errmsg=msg)
end subroutine
end program
