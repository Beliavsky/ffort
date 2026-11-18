program p
implicit none
integer,allocatable :: a(:)
integer :: stat
character(80) :: msg
deallocate(a,stat=stat,errmsg=msg)
if(stat==0.or.len_trim(msg)==0) error stop 1
end program
