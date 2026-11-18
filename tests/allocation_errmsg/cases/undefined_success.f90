program p
implicit none
integer,allocatable :: a(:)
integer :: stat
character(80) :: msg
allocate(a(1),stat=stat,errmsg=msg)
if(stat/=0.or.len(msg)/=80) error stop 1
msg='now defined'
if(trim(msg)/='now defined') error stop 2
end program
