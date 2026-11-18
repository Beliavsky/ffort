program p
implicit none
character(80) :: msg
integer :: stat
call q(msg,stat)
if(stat==0.or.len_trim(msg)==0) error stop 1
contains
subroutine q(msg,stat)
character(*),intent(out) :: msg
integer,intent(out) :: stat
integer,allocatable :: a(:)
deallocate(a,stat=stat,errmsg=msg)
end subroutine
end program
