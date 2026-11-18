program p
implicit none
integer,allocatable :: a(:)
character(80) :: msg

deallocate(a,errmsg=msg)
print *,'must not execute' 
end program
