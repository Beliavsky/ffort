program test
implicit none
integer,allocatable::c
allocate(c)
call system_clock(c)

end program
