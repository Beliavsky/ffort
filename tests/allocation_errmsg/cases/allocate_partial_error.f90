program p
implicit none
integer,allocatable :: a(:),b(:),c(:)
integer :: stat
character(80) :: msg
allocate(b(1))
allocate(a(1),b(2),c(3),stat=stat,errmsg=msg)
if(stat==0.or.len_trim(msg)==0) error stop 1
if(.not.allocated(a).or..not.allocated(b).or.allocated(c)) error stop 2
end program
