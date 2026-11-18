program test
implicit none
integer,target::a
integer,pointer::c
c=>a
call system_clock(c)

end program
