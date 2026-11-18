program p
implicit none
integer,allocatable :: a(:)
character(8) :: msg
msg='retained'
allocate(a(1),errmsg=msg)
deallocate(a,errmsg=msg)
if(msg/='retained') error stop 1
end program
