program test
implicit none

call q()
contains
subroutine q(t)
real,optional,intent(out)::t
call cpu_time(t)
end subroutine
end program
