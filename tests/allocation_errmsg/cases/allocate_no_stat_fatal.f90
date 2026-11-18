program p
implicit none
integer,allocatable :: a(:)
character(80) :: msg
allocate(a(1))
allocate(a(1),errmsg=msg)
print *,'must not execute' 
end program
