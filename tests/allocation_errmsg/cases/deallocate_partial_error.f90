program p
implicit none
integer,allocatable :: a(:),b(:),c(:)
integer :: stat
character(80) :: msg
allocate(a(1),c(1))
deallocate(a,b,c,errmsg=msg,stat=stat)
if(stat==0.or.len_trim(msg)==0) error stop 1
if(allocated(a).or.allocated(b).or..not.allocated(c)) error stop 2
end program
