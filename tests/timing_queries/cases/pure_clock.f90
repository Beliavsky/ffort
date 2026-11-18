program test
implicit none
integer::n
call q(n)
contains
pure subroutine q(n)
integer,intent(out)::n
call system_clock(n)
end subroutine
end program
