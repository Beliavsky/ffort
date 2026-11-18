program test
implicit none
integer::n
call q(n)
contains
simple subroutine q(n)
integer,intent(out)::n
call system_clock(n)
end subroutine
end program
